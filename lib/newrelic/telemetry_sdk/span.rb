# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'newrelic/telemetry_sdk/util'

module Newrelic
  module TelemetrySdk
    class Span
      attr_reader :contents

      def initialize(name,
                     id: Util.generate_guid(8),
                     trace_id: Util.generate_guid(16),
                     timestamp: Util.time_to_ms,
                     duration: nil,
                     parent_id: nil,
                     service_name: nil,
                     custom_attributes: nil)

        @attributes = {
          name: name,
          duration: duration,
          parent_id: parent_id,
          service_name: service_name
        }

        @attributes.merge!(custom_attributes) if custom_attributes

        @contents = {
          id: id,
          trace_id: trace_id,
          timestamp: timestamp,
          attributes: @attributes
        }
      end

      def finish(end_time_ms: Util.time_to_ms)
        duration = end_time_ms - @contents[:timestamp]
        @contents[:duration] = duration
      end
    end
  end
end
