# frozen_string_literal: true

require_relative './listener_pool'
module Nagare
  ##
  # Listener is a base class for your own listeners.
  #
  # It defines default behaviour for #handle_event, invoking a method on the
  # listener with the same name as the event if such method exists.
  #
  # It also adds the `stream` class method, that when used causes the listener
  # to register itself with the listener pool for receiveing messages.
  class Listener
    ##
    # Class methods that automatically get added to inheriting classes
    module ClassMethods
      ##
      # Defines the name of the stream this listener listens to.
      #
      # This method causes the listener to register itself with
      # the listener pool, creating automatically a consumer group
      # if none exists for the stream, and the stream itself if not
      # initialized.
      #
      # Defining a stream is required for every listener, failing
      # to do so will cause the listener never to be invoked.
      #
      # @param name [String] name of the stream the listener should listen to.
      def stream(name)
        class_variable_set(:@@stream_name, name)

        # Force consumer group creation
        Nagare::ListenerPool.listener_pool
        name
      end

      def stream_name
        class_variable_get(:@@stream_name)
      end
    end

    ##
    # The ClassMethods module is automatically loaded into child classes
    # effectively adding the `stream` class method to the child class.`
    def self.inherited(subclass)
      subclass.extend(ClassMethods)
    end

    ##
    # This method gets called by the ListenerPool when messages are received
    # from redis. You may override it in your own listener if you so wish.
    #
    # The default implementation works based on the following convention:
    # Listeners define methods with the name of the event they handle.
    #
    # Events in nagare are always stored in redis as { event_name: data }
    def handle_event(event)
      event_name = event.keys.first
      Nagare.logger.debug("Received #{event}")
      return unless respond_to?(event_name)

      send(event_name, JSON.parse(event[event_name], symbolize_names: true))
    end
  end
end
