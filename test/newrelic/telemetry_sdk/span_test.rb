# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'newrelic/telemetry_sdk/span'
require 'newrelic/telemetry_sdk/util'

module Newrelic
  module TelemetrySdk
    class SpanTest < Minitest::Test
      def test_required_attributes
        span = Span.new("Name")
        assert span.id.is_a? String
        assert span.trace_id.is_a? String
        assert span.timestamp_ms.is_a? Integer

        # Note: should this go in recommended attributes?
        # It is recommended from the point of view of the
        # Trace API but at least some Telemetry SDK implementations
        # do require it on span creation.
        assert_equal "Name", span.name
        assert span.name.is_a? String
      end

      def test_recommended_attributes
        span = Span.new("Name",
                        duration_ms: 123456,
                        parent_id: "c617c2813a222a34",
                        service_name: "My Service")

        assert_equal 123456, span.duration_ms
        assert span.duration_ms.is_a? Integer

        assert_equal "c617c2813a222a34", span.parent_id
        assert span.parent_id.is_a? String

        assert_equal "My Service", span.service_name
        assert span.service_name.is_a? String
      end

      def test_custom_attributes
        custom_attributes = {
          :'user.email' => "me@newr.com",
          :custom_key   => "custom_value"
        }

        span = Span.new("Name", custom_attributes: custom_attributes)

        assert_equal custom_attributes, span.custom_attributes
      end

      def test_finish
        span = Util.stub :time_to_ms, 0 do
          start_time_ms = Util.time_to_ms
          Span.new("Name", timestamp_ms: start_time_ms)
        end

        Util.stub :time_to_ms, 1000 do
          end_time_ms = Util.time_to_ms
          span.finish(end_time_ms: end_time_ms)
        end

        assert_equal 1000, span.duration_ms
      end

      def test_to_json
        id = Util.generate_guid(8)
        trace_id = Util.generate_guid(16)
        timestamp_ms = Util.time_to_ms

        duration_ms = 1000
        end_time_ms = timestamp_ms + 1000
        custom_attributes = { :custom_key => "custom_value" }

        span = Span.new("Name",
                        id: id,
                        trace_id: trace_id,
                        timestamp_ms: timestamp_ms,
                        parent_id: "c617c2813a222a34",
                        service_name: "My Service",
                        custom_attributes: custom_attributes)

        Process.stub :clock_gettime, 1 do
          span.finish(end_time_ms: end_time_ms)
        end

        expected_data = {
          :id => id,
          :'trace.id' => trace_id,
          :timestamp  => timestamp_ms,
          :attributes => {
            :'duration.ms'  => duration_ms,
            :'parent.id'    => "c617c2813a222a34",
            :'service.name' => "My Service",
            :custom_key   => "custom_value"
          }
        }.to_json

        assert_equal expected_data, span.to_json
      end
    end
  end
end
