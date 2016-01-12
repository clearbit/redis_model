module RedisModel
  module AutoId
    def id
      values[self.class.primary_key] ||= generate_id
    end

    def save(options = {})
      id

      super
    end

    private

    def generate_id
      SecureRandom.hex(10)
    end
  end
end
