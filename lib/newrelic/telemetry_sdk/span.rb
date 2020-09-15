# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'newrelic/telemetry_sdk/util'
require 'json'

module Newrelic
  module TelemetrySdk
    class Span
      attr_reader :name,
                  :id,
                  :trace_id,
                  :timestamp_ms,
                  :duration_ms,
                  :parent_id,
                  :service_name,
                  :custom_attributes

      def initialize name,
                     id: Util.generate_guid(8),
                     trace_id: Util.generate_guid(16),
                     timestamp_ms: Util.time_to_ms,
                     duration_ms: nil,
                     parent_id: nil,
                     service_name: nil,
                     custom_attributes: nil

        @name = name
        @id = id
        @trace_id = trace_id
        @timestamp_ms = timestamp_ms
        @duration_ms = duration_ms
        @parent_id = parent_id
        @service_name = service_name
        @custom_attributes = custom_attributes
      end

      def finish end_time_ms: Util.time_to_ms
        @duration_ms = end_time_ms - @timestamp_ms
      end

      def to_h
        data = {
          :id => @id,
          :'trace.id' => @trace_id,
          :timestamp => @timestamp_ms,
          :attributes => {
            :'duration.ms' => @duration_ms,
            :'parent.id' => @parent_id,
            :'service.name' => @service_name
          }
        }

        data[:attributes].merge! @custom_attributes if @custom_attributes

        data
      end

      def to_json
        to_h.to_json
      end
    end
  end
end
