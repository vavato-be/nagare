# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nagare::Listener do
  describe '.inherited gets called automatically when a class inherits from it' do
    it 'adds a ".stream" method to the child class' do
      klazz = Class.new(Nagare::Listener) do
        stream :listener_spec_stream
      end
      expect(klazz.methods).to include(:stream)
    end
  end

  describe '.stream' do
    let(:stream) { :listener_spec_stream }

    it 'sets the stream_name class variable' do
      klazz = Class.new(Nagare::Listener) do
        stream :listener_spec_stream
      end
      expect(klazz.stream_name).to eq stream
    end
  end

  describe '#handle_event' do
    subject(:listener) { listener_class.new }

    let(:listener_class) do
      Class.new(Nagare::Listener) do
        stream :listener_spec_stream

        def handler_called?
          @handler_called ||= false
        end

        attr_reader :data

        def test_happened(the_data)
          @data = the_data
          @handler_called = true
        end
      end
    end

    context 'when the listener has a method matching the event name' do
      it 'calls the method matching the event name on the listener' do
        listener.handle_event(test_happened: { foo: 'bar' }.to_json)
        expect(listener.handler_called?).to be true
      end

      it 'calls the method with the data JSON deserialized' do
        listener.handle_event(test_happened: { foo: 'bar' }.to_json)
        expect(listener.data).to include({ foo: 'bar' })
      end
    end

    context 'when the listener does not have any method matching the event name' do
      it 'does not call the handler methods' do
        listener.handle_event(something_happened: { foo: 'bar' }.to_json)
        expect(listener.handler_called?).to be false
      end
    end
  end
end
