module RedisModel
  module CustomSerializers
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.class_eval do
        @format_serializers = {
          json: [
            ->(v) { JSON.dump(v) },
            ->(v) { JSON.parse(v, quirks_mode: true, symbolize_names: true) }
          ],
          mash: [
            ->(v) { JSON.dump(v) },
            ->(v) { Mash.new(JSON.parse(v, quirks_mode: true)) }
          ]
        }

        @serializers = Hash.new(
          [
            ->(v) { JSON.dump(v) },
            ->(v) { JSON.parse(v, quirks_mode: true) }
          ]
        )
      end
    end

    module ClassMethods
      def serializer(attr)
        serializer = @serializers[attr.to_sym]
        if serializer.is_a?(Symbol)
          @format_serializers[serializer]
        else
          serializer
        end
      end

      def serialize_attr(attr, value)
        serializer(attr)[0].call(value)
      rescue StandardError
        raise SerializeError, "Failed to serialize: #{attr}"
      end

      def deserialize_attr(attr, value)
        serializer(attr)[1].call(value)
      rescue StandardError
        raise DeserializeError, "Failed to deserialize: #{attr}"
      end

      def serialize_attributes(serializers = nil, *attrs)
        return @serializers unless serializers
        attrs.each do |attr|
          @serializers[attr] = serializers
        end
      end
    end
  end
end
