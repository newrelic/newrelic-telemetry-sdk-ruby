# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'new_relic/telemetry_sdk/util'
require 'new_relic/telemetry_sdk/logger'

module NewRelic
  module TelemetrySdk
    class Span
      include NewRelic::TelemetrySdk::Logger

      attr_accessor :id,
                    :trace_id,
                    :start_time_ms,
                    :duration_ms,
                    :name,
                    :parent_id,
                    :service_name,
                    :custom_attributes

      def initialize id: Util.generate_guid(16),
                     trace_id: Util.generate_guid(32),
                     start_time_ms: Util.time_to_ms,
                     duration_ms: nil,
                     name: nil,
                     parent_id: nil,
                     service_name: nil,
                     custom_attributes: nil

        @id = id
        @trace_id = trace_id
        @start_time_ms = start_time_ms
        @duration_ms = duration_ms
        @name = name
        @parent_id = parent_id
        @service_name = service_name
        @custom_attributes = custom_attributes
      end

      def finish end_time_ms: Util.time_to_ms
        @duration_ms = end_time_ms - @start_time_ms
      rescue => e
        log_error e, "Encountered error finishing span"
      end

      def to_h
        data = {
          :id => @id,
          :'trace.id' => @trace_id,
          :timestamp => @start_time_ms,
          :attributes => {
            :'duration.ms' => @duration_ms,
            :name => @name,
            :'parent.id' => @parent_id,
            :'service.name' => @service_name
          }
        }

        data[:attributes].merge! @custom_attributes if @custom_attributes

        data
      rescue => e
        log_error e, "Encountered error converting span to hash"
      end
    end
  end
end
