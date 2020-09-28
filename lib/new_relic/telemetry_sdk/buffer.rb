# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    class Buffer
      attr_reader :items
      attr_accessor :common_attributes

      CAPACITY = 2000

      def initialize common_attributes=nil
        @items = []
        @common_attributes = common_attributes
        @lock = Mutex.new
        @capacity = capacity
      end

      # Items recorded into the buffer must have a to_h method for transformation
      def record item
        @lock.synchronize do
          if size < capacity
            @items << item
          end
        end
      end

      def flush
        data = nil
        @lock.synchronize do
          data = @items.map(&:to_h)
          @items = []
        end
        return data, @common_attributes
      end

      alias_method :to_h, :flush

      def size
        @items.length
      end

      def capacity
        CAPACITY
      end
    end
  end
end
