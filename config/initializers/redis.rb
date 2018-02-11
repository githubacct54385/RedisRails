# Redis Module for all Redis usages in application
module RedisModule
  class << self
    def redis
      redis_url = ENV['REDIS_URL']
      redis_ip = 'redis://127.0.0.1:6379'
      @redis ||= Redis.new(url: (redis_url || redis_ip))
    end
  end
end
