# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    class Buffer
      include NewRelic::TelemetrySdk::Logger

      attr_reader :items
      attr_accessor :common_attributes

      def initialize common_attributes=nil
        @items = []
        @common_attributes = common_attributes
        @lock = Mutex.new
      end

      # Items recorded into the buffer must have a to_h method for transformation
      def record item
        @lock.synchronize { @items << item }
      rescue => e
        log_error e, "Encountered error while recording in buffer"
      end

      def flush
        data = nil
        @lock.synchronize do
          data = @items
          @items = []
        end
        data.map!(&:to_h)
        return data, @common_attributes
      rescue => e
        log_error e, "Encountered error while flushing buffer"
      end
    end
  end
end
