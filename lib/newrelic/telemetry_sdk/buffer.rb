# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    # Buffers store discrete pieces of data (e.g. Spans) until they are
    # sent via a timed {Harvester}. Batches of data may also be flushed
    # from a buffer and sent directly through the client.
    #
    # @api public
    class Buffer

      include NewRelic::TelemetrySdk::Logger

      attr_reader :items
      attr_accessor :common_attributes

      # Record a discrete piece of data (e.g. a Span) into the buffer
      # for batching purposes.
      # @param common_attributes [optional, Hash]
      #     Attributes that should be added to every item in the batch
      #     e.g. +{host: 'my_host'}+
      #
      # @api public
      def initialize common_attributes=nil
        @items = []
        @common_attributes = common_attributes
        @lock = Mutex.new
      end

      # Record a discrete piece of data (e.g. a Span) into the buffer.
      # @param item [Span, etc.]
      #     A piece of data to record into the buffer. Must have a to_h method
      #     for transformation.
      #
      # @api public
      def record item
        @lock.synchronize { @items << item }
      rescue => e
        log_error "Encountered error while recording in buffer", e
      end

      # Return a batch of data that has been collected in this buffer
      # as an Array of Hashes. Also returns a Hash of any common attributes
      # that have been set on the buffer to be attached to each individual data item.
      #
      # @api public
      def flush
        data = nil
        @lock.synchronize do
          data = @items
          @items = []
        end
        data.map!(&:to_h)
        return data, @common_attributes
      rescue => e
        log_error "Encountered error while flushing buffer", e
      end
    end
  end
end
