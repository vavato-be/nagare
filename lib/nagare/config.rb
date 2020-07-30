# frozen_string_literal: true

module Nagare
  # Configuration class for Nagare.
  # See the README for possible values and what they do
  class Config
    class << self
      attr_accessor :dead_consumer_timeout, :group_name, :redis_url, :threads,
                    :suffix

      # Runs code in the block passed in to configure Nagare and sets defaults
      # when values are not set.
      #
      # returns Nagare::Config self
      def configure
        yield(self)
        @dead_consumer_timeout ||= 5000
        @group_name ||= 'nagare'
        @redis_url = redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379'
        @threads ||= 1
        @suffix ||= nil
        self
      end
    end
  end
end
