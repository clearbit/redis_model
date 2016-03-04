module RedisModel
  module DefaultValues
    def self.included(base)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def default_values(generator = nil, *attrs)
        @default_values ||= {}
        return @default_values unless generator
        attrs.each do |attr|
          @default_values[attr] = generator
        end
      end
    end

    def initialize(values = {})
      super(values)
      set_default_values
    end

    def reload
      super
      set_default_values

      self
    end

    private

    def set_default_values
      self.class.default_values.each do |attr, generator|
        attr_name = attr.to_s
        @values[attr_name] = generator.call unless @values.key?(attr_name)
      end
    end
  end
end
