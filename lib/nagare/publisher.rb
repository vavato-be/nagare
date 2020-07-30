module Nagare
  ##
  # Publisher is a mixin that allows classes to easily publish events
  # to a redis stream.
  module Publisher
    ##
    # Class methods that get injected into a class or module that extends Publisher
    module ClassMethods
      attr_accessor :redis_publisher_stream
      ##
      # Defines which stream to use for publish when none is specified
      #
      # The stream is automatically created by Redis if it doesn't exist
      # when a message is first published to it.
      #
      # Defaults to the name of the class publishing the message
      #
      # @param [String] name name of the stream
      def stream(name)
        self.redis_publisher_stream = name.to_s
      end
    end

    ##
    # Publishes a message to the configured stream for this class.
    #
    # The message is always in the format { event_name: data }
    # hence the 2 separate parameters for this method.
    #
    # Event name will be used on the listener side to determine
    # which method of the listener to invoke.
    #
    # @param event_name [String] event_name name of the event. If it matches
    #  a method on a listener on this stream, that method will be
    #  invoked upon receiving the message
    # @param data       [Object] an object representing the data
    # @param stream     [String] name of the stream to publish to
    def publish(event_name, data, stream = nil)
      stream ||= stream_name
      Nagare.logger.info "Publishing to stream #{stream}: #{event_name}: #{data}"
      Nagare::RedisStreams.publish(stream, event_name, data.to_json)
    end

    ##
    # Returns the name of the configured or default stream for this
    # publisher class.
    #
    # @return [String] stream name
    def stream_name
      own_class = self.class
      own_class.redis_publisher_stream || own_class.name.downcase
    end

    class << self
      def included(base)
        base.extend ClassMethods
      end
    end
  end
end
