module RedisModel
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
      data.empty? ? nil : self.new(deserialize(data))
    end

    def self.deserialize(data)
      data.inject({}) do |hash, (key, value)|
        hash.merge(key => JSON.parse(value)['v'])
      end
    end

    def self.create(values)
      self.new(values).save
    end

    attr_reader :values

    def initialize(values = {})
      @values = {}

      set(values)
    end

    def set(new_values)
      values.merge!(stringify_hash(new_values))
    end

    def update_all(values)
      values.each do |key, value|
        client.hset(self.key, key, serialize(value))
      end

      reload

      self
    end

    def save(options = {})
      set_values = values.merge(id: id)

      client.mapped_hmset(
        key, serialize_hash(set_values)
      )

      self
    end

    def id
      values[self.class.primary_key] ||= generate_id
    end

    def key(*params)
      self.class.key(id, *params)
    end

    alias_method :respond_to_without_values?, :respond_to?

    def respond_to?(method, include_priv = false)
      method_name = method.to_s
      if values.nil?
        super
      elsif method_name =~ /(?:=|\?)$/ && values.include?($`)
        true
      else
        super
      end
    end

    def method_missing(method_symbol, *arguments) #:nodoc:
      method_name = method_symbol.to_s

      if method_name =~ /(=|\?)$/
        case $1
        when "="
          values[$`] = arguments.first
        when "?"
          values[$`]
        end
      else
        if values.include?(method_name)
          return values[method_name]
        end

        super
      end
    end

    protected

    def reload
      new_values = client.hgetall(key)
      new_values = self.class.deserialize(new_values)

      values.replace(new_values)
    end

    def stringify_hash(hash)
      hash.inject({}) do |new_hash, (key, value)|
        new_hash.merge(key.to_s => value)
      end
    end

    def serialize(value)
      JSON.dump(v: value)
    end

    def serialize_hash(hash)
      hash.inject({}) do |new_hash, (key, value)|
        new_hash.merge(key => serialize(value))
      end
    end

    def client
      self.class.client
    end

    def generate_id
      SecureRandom.hex(10)
    end
  end
end
