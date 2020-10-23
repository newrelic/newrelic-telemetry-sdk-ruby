# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'new_relic/telemetry_sdk/util'

module NewRelic
  module TelemetrySdk
    class Span
      attr_accessor :id,
                    :trace_id,
                    :start_time,
                    :duration_ms,
                    :name,
                    :parent_id,
                    :service_name,
                    :custom_attributes

      def initialize id: Util.generate_guid(16),
                     trace_id: Util.generate_guid(32),
                     start_time: Util.current_time,
                     duration_ms: nil,
                     name: nil,
                     parent_id: nil,
                     service_name: nil,
                     custom_attributes: nil

        @id = id
        @trace_id = trace_id
        @start_time = start_time
        @duration_ms = duration_ms
        @name = name
        @parent_id = parent_id
        @service_name = service_name
        @custom_attributes = custom_attributes
      end

      def finish end_time: Util.current_time
        @duration_ms = Util.time_to_ms(end_time - @start_time)
      end

      def to_h
        data = {
          :id => @id,
          :'trace.id' => @trace_id,
          :timestamp => Util.time_to_ms(@start_time),
          :attributes => {
            :'duration.ms' => @duration_ms,
            :name => @name,
            :'parent.id' => @parent_id,
            :'service.name' => @service_name
          }
        }

        data[:attributes].merge! @custom_attributes if @custom_attributes

        data
      end
    end
  end
end
