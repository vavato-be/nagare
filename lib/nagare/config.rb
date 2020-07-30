module Nagare
  class Config
    class << self
      attr_accessor :dead_consumer_timeout, :group_name, :redis_url, :threads, :suffix

      def configure
        yield(self)
        dead_consumer_timeout ||= 5000
        group_name ||= 'nagare'
        redis_url = redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379'
        threads ||= 1
        suffix ||= nil
      end
    end
  end
end
