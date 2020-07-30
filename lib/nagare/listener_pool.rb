module Nagare
  ##
  # ListenerPool acts both as a registry of all listeners in the application
  # and as the polling mechanism that retrieves messages from redis using
  # consumer groups and deivers them to registered listenersone at a time.
  class ListenerPool

    class << self
      ##
      # A registry of listeners in the format { stream: [listeners...]}
      #
      # @return [Hash] listeners
      def listener_pool
        listeners = ObjectSpace.each_object(Class).select { |klass| klass < Nagare::Listener }
        listeners.each_with_object({}) do |listener, hash|
          stream = listener.stream_name

          unless hash.key?(listener.stream_name)
            logger.debug("Assigned stream #{stream} to listener #{listener.name}")
            created = create_and_subscribe_to_stream(stream)
            logger.debug("Created group and/or stream for stream #{stream}") if created
            hash[stream] = []
          end
          hash[stream] << listener
          hash
        end
      end

      ##
      # Initiates polling of redis and distribution of messages to listeners in a thread
      #
      # @return [Thread] the listening thread
      def start_listening
        logger.info "Starting Nagare thread"
        Thread.new do
          loop do
            poll
            sleep 1
          end
        end
      end

      ##
      # Polls redis for new messages on all registered streams and delivers
      # messages to the registered listeners. If the listener does not raise any errors,
      # automatically ACKs the message to the redis consumer group.
      def poll
        self.listener_pool.each do |stream, listeners|
          poll_stream(stream, listeners)
        end
      end

      private

      def poll_stream(stream, listeners)
        #TODO: Use thread pool
        messages = Nagare::RedisStreams.read_next_messages(stream, group)
        return unless messages.any?

        messages.each do |message|
          deliver_message(stream, message, listeners)
        end
      end

      def deliver_message(stream, message, listeners)
        listener_failed = false
        listeners.each do |listener|
          invoke_listener(stream, message, listener)
        rescue => e
          #TODO: Retry logic
          logger.error e.message
          logger.error e.backtrace.join("\n")
          listener_failed = true
          #TODO: Notify Appsignal
        end
        Nagare::RedisStreams.mark_processed(stream, group, message[0]) unless listener_failed
      end

      def invoke_listener(stream, message, listener)
        #TODO: Transactions
        logger.info "Invoking listener #{listener.name} for stream #{stream} with message #{message}"
        listener.new.handle_event(message[1])
      end

      def logger
        Nagare.logger
      end

      def group
        Nagare::Config.group_name
      end

      def create_and_subscribe_to_stream(stream)
        unless Nagare::RedisStreams.group_exists?(stream, group)
          logger.info("Creating listener group #{group} for stream #{stream}")
          Nagare::RedisStreams.create_group(stream, group)
          return true
        end
        false
      end
    end
  end
end
