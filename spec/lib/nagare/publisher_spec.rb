# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nagare::Publisher do
  subject(:publisher) { publisher_class.new }

  let(:publisher_class) do
    Class.new do
      include Nagare::Publisher

      def self.name
        'TestPublisher'
      end
    end
  end

  let(:rspec_stream) { 'rspec_stream' }

  before do
    Nagare::RedisStreams.truncate(rspec_stream)
    Nagare::RedisStreams.truncate(publisher_class.name.downcase)
    Nagare::RedisStreams.truncate('new_stream')
  end

  describe '.included is called automatically after a class includes the module' do
    it "defines a '.stream' method in the including class" do
      expect(publisher_class.methods).to include(:stream)
    end
  end

  describe '#publish' do
    it 'publishes a message to the specified redis stream' do
      message_id = publisher.publish('some_event_fired', { foo: 'bar' },
                                     rspec_stream)
      expect(Nagare::RedisStreams.read_one(rspec_stream).first).to eq message_id
    end

    it 'transforms the message into a { event_name: data } hash with json data' do
      message_id = publisher.publish('some_event_fired', { foo: 'bar' },
                                     rspec_stream)
      expect(Nagare::RedisStreams.read_one(rspec_stream)).to match([message_id,
                                                                    { 'some_event_fired' => { foo: 'bar' }.to_json }])
    end

    describe 'has an optional stream parameter' do
      context 'when a stream IS NOT configured for the class' do
        context 'when the stream parameter IS NOT passed in' do
          it 'defaults to the class name as the name of the stream' do
            message_id = publisher.publish('some_event_fired', { foo: 'bar' })
            expect(Nagare::RedisStreams.read_one(publisher_class.name.downcase).first).to eq message_id
          end
        end

        context 'when the stream parameter IS passed in' do
          it 'publishes to the stream provided' do
            message_id = publisher.publish('some_event_fired', { foo: 'bar' },
                                           rspec_stream)
            expect(Nagare::RedisStreams.read_one(rspec_stream).first).to eq message_id
          end
        end
      end

      context 'when a stream IS configured for the class' do
        let(:publisher_class) do
          Class.new do
            include Nagare::Publisher
            stream :new_stream

            def self.name
              'TestPublisher'
            end
          end
        end

        context 'when the stream parameter IS NOT passed in' do
          it 'defaults to the class name as the name of the stream' do
            message_id = publisher.publish('some_event_fired', { foo: 'bar' })
            expect(Nagare::RedisStreams.read_one('new_stream').first).to eq message_id
          end
        end

        context 'when the stream parameter IS passed in' do
          it 'publishes to the stream provided' do
            message_id = publisher.publish('some_event_fired', { foo: 'bar' },
                                           rspec_stream)
            expect(Nagare::RedisStreams.read_one(rspec_stream).first).to eq message_id
          end
        end
      end
    end
  end
end
