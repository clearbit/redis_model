require 'json'
require 'redis'
require 'redis_model/version'

module RedisModel
  autoload :Base,              'redis_model/base'
  autoload :CustomSerializers, 'redis_model/custom_serializers'
  autoload :DefaultValues,     'redis_model/default_values'
end
