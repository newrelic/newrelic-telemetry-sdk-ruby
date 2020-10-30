# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    # This class represents a timed operation that is part of a distributed trace.
    # This operation will be represented as a Span in the New Relic UI.
    #
    # @api public
    class Span
      include NewRelic::TelemetrySdk::Logger

      attr_accessor :id,
                    :trace_id,
                    :start_time,
                    :duration_ms,
                    :name,
                    :parent_id,
                    :service_name,
                    :custom_attributes

      # @param id [optional, String]
      #     A random, unique identifier associated with this specific New Relic span.
      # @param trace_id [optional, String]
      #     A random, unique identifier associated with a collection of spans that
      #     will be grouped together as a trace in the New Relic UI.
      # @param start_time [optional, Time]
      #     A Time object corresponding to the start time of the operation represented
      #     by this span.
      # @param duration_ms [optional, Integer]
      #     The duration of the operation represented by this span, in milliseconds.
      # @param name [optional, String]
      #     The name of the span.
      # @param parent_id [optional, String]
      #     A random, unique identifier associated with the parent of this span.
      # @param service_name [optional, String]
      #     The name of the entity that created this span.
      # @param custom_attributes [optional, Hash]
      #     Custom attributes that will appear on this span.
      # @see https://docs.newrelic.com/docs/understand-dependencies/distributed-tracing/trace-api/report-new-relic-format-traces-trace-api#other-attributes Report Traces (New Relic format)
      #
      # @api public
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

      # Mark the operation represented by this Span as finished and calculate is duration.
      # @param end_time [optional, Time]
      #     A Time object corresponding to the end time of the operation represented
      #     by this span.
      #
      # @api public
      def finish end_time: Util.current_time
        @duration_ms = Util.time_to_ms(end_time - @start_time)
      rescue => e
        log_error "Encountered error finishing span", e
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
      rescue => e
        log_error "Encountered error converting span to hash", e
      end
    end
  end
end
