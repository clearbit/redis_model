module RedisModel
  class SerializeError < RuntimeError
  end

  class DeserializeError < RuntimeError
  end

  class PrimaryKeyError < RuntimeError
  end

  class Base
    def self.namespace=(value)
      @namespace = value
    end

    def self.namespace
      @namespace ||= 'rm'
    end

    def self.primary_key=(value)
      @primary_key = value
    end

    def self.primary_key
      @primary_key ||= 'id'
    end

    def self.key(*params)
      parts = [namespace, name.to_s, *params]
      parts.compact.join(':').downcase
    end

    def self.client
      Redis.current
    end

    def self.[](id)
      data = client.hgetall(key(id))
      data.empty? ? nil : new(deserialize(data))
    end

    def self.serialize_attr(attr, value)
      JSON.dump(value)
    rescue StandardError
      raise SerializeError, "Failed to serialize: #{attr}"
    end

    def self.deserialize_attr(attr, value)
      JSON.parse(value, quirks_mode: true)
    rescue StandardError
      raise DeserializeError, "Failed to deserialize: #{attr}"
    end

    def self.deserialize(data)
      data.each_with_object({}) do |(attr, value), hash|
        hash[attr.to_s] = deserialize_attr(attr, value)
      end
    end

    def self.serialize_hash(hash)
      hash.each_with_object({}) do |(attr, value), new_hash|
        new_hash[attr.to_s] = serialize_attr(attr, value)
      end
    end

    def self.create(values)
      new(values).save
    end

    attr_reader :values

    def initialize(values = {})
      @values = {}

      set(values)
    end

    def set(new_values)
      new_values.each do |attr, value|
        values[attr.to_s] = value
      end
    end

    def update_all(new_values)
      new_values[self.class.primary_key] ||= values[self.class.primary_key]
      client.mapped_hmset(key, self.class.serialize_hash(new_values))

      reload

      self
    end

    def save(options = {})
      client.mapped_hmset(key, self.class.serialize_hash(values))

      self
    end

    def delete
      client.del(key)
    end

    def reload
      new_values = client.hgetall(key)

      values.replace(self.class.deserialize(new_values))

      self
    end

    def key(*params)
      id = values[self.class.primary_key]
      raise PrimaryKeyError, 'primary key is nil' if id.nil?

      self.class.key(id, *params)
    end

    alias_method :respond_to_without_values?, :respond_to?

    def respond_to?(method, *arguments)
      method_name = method.to_s

      values.key?(method_name.sub(/(?:=|\?)$/, '')) || super
    end

    def method_missing(method_symbol, *arguments) #:nodoc:
      method_name = method_symbol.to_s

      return values[method_name] if values.key?(method_name)

      if m = /(=|\?)$/.match(method_name)
        case m.captures[0]
        when '='
          values[m.pre_match] = arguments.first
        when '?'
          respond_to?(m.pre_match) ? send(m.pre_match) : nil
        end
      else
        super
      end
    end

    private

    def client
      self.class.client
    end
  end
end
