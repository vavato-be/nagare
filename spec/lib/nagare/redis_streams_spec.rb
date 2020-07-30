# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Nagare::RedisStreams do
  describe 'mark_processed' do
    let(:stream) { 'nagare_redis_streams_spec' }
    let(:group) { 'monolith' }

    # Remove existing group or stream
    before do
      described_class.delete_group(stream, group)
      described_class.truncate(stream)
    rescue StandardError => e
      puts e.message
    end

    context 'when a message is published on a stream with an existing consumer group' do
      # Create stream and group. Messages before the creation of the
      # group are not taken into consideration for reading.
      before do
        described_class.create_group(stream, group)
        described_class.publish(stream, :myevent, { foo: 'bar' })
      end

      it 'acknowledges processing of a message in a consumer group' do
        message = described_class.read_next_messages(stream, group)[0]
        described_class.mark_processed(stream, group, message[0])

        pending = described_class.pending(stream, group)
        expect(pending['size']).to eq 0
      end
    end
  end
end
