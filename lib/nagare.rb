# frozen_string_literal: true

require 'logger'
require 'json'
require 'redis'
require 'nagare/version'
require 'nagare/config'
require 'nagare/redis_streams'
require 'nagare/listener'
require 'nagare/publisher'
require 'nagare/listener_pool'

#
# Nagare: Redis Streams wrapper for pub/sub with durable consumers
# see https://github.com/vavato-be/nagare
module Nagare
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout).tap do |log|
        log.progname = name
      end
    end
  end
end
