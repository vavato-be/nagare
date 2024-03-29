# frozen_string_literal: true

module Nagare
  # Configuration class for Nagare.
  # See the README for possible values and what they do
  class Config
    class << self
      attr_accessor :group_name, :redis_url, :threads, :suffix, :min_idle_time,
                    :error_handler, :dlq_stream, :max_retries

      # Runs code in the block passed in to configure Nagare and sets defaults
      # when values are not set.
      #
      # returns [Nagare::Config] self
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
      def configure
        yield(self)
        @dead_consumer_timeout ||= 5000
        @group_name ||= 'nagare'
        @redis_url = redis_url || ENV['REDIS_URL'] || 'redis://localhost:6379'
        @threads ||= 1
        @suffix ||= nil
        @min_idle_time ||= 600_000
        @error_handler ||= proc do |message, error|
          Nagare.logger.error "Failed to process message #{message}"
          Nagare.logger.error error.message
          Nagare.logger.error error.backtrace.join("\n")
        end
        @dlq_stream ||= 'dlq'
        @max_retries ||= 10
        self
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
