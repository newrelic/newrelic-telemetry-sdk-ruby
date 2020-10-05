# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'new_relic/telemetry_sdk/span'
require 'new_relic/telemetry_sdk/util'

module NewRelic
  module TelemetrySdk
    class SpanTest < Minitest::Test
      def test_required_attributes
        span = Span.new
        assert span.id.is_a? String
        assert span.trace_id.is_a? String
        assert span.start_time_ms.is_a? Integer
      end

      def test_recommended_attributes
        span = Span.new duration_ms: 123456,
                        parent_id: "c617c2813a222a34",
                        name: "Name",
                        service_name: "My Service"

        assert_equal 123456, span.duration_ms
        assert span.duration_ms.is_a? Integer

        assert_equal "Name", span.name
        assert span.name.is_a? String

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

        span = Span.new custom_attributes: custom_attributes

        assert_equal custom_attributes, span.custom_attributes
      end

      def test_adding_attributes_after_span_creation
        custom_attributes = {
          :'user.email' => "me@newr.com",
          :custom_key   => "custom_value"
        }

        span = Span.new

        span.custom_attributes = custom_attributes
        span.service_name = 'My Service'

        assert_equal custom_attributes, span.custom_attributes
        assert_equal 'My Service', span.service_name
      end

      def test_finish_with_end_time_supplied
        time = Time.now

        Timecop.freeze(time) do
          start_time_ms = Util.time_to_ms
          span = Span.new start_time_ms: start_time_ms

          new_time = time + 1
          Timecop.travel(new_time)
          end_time_ms = Util.time_to_ms
          span.finish end_time_ms: end_time_ms

          assert_equal 1000, span.duration_ms
        end
      end

      def test_finish_without_end_time_supplied
        time = Time.now

        Timecop.freeze(time) do
          start_time_ms = Util.time_to_ms
          span = Span.new start_time_ms: start_time_ms

          new_time = time + 1
          Timecop.travel(new_time)
          span.finish

          assert_equal 1000, span.duration_ms
        end
      end

      def test_to_h
        id = Util.generate_guid 8
        trace_id = Util.generate_guid 16
        start_time_ms = Util.time_to_ms

        duration_ms = 1000
        end_time_ms = start_time_ms + 1000
        custom_attributes = { :custom_key => "custom_value" }

        span = Span.new id: id,
                        trace_id: trace_id,
                        start_time_ms: start_time_ms,
                        name: "Name",
                        parent_id: "c617c2813a222a34",
                        service_name: "My Service",
                        custom_attributes: custom_attributes

        Process.stub :clock_gettime, 1 do
          span.finish end_time_ms: end_time_ms
        end

        expected_data = {
          :id => id,
          :'trace.id' => trace_id,
          :timestamp  => start_time_ms,
          :attributes => {
            :'duration.ms' => duration_ms,
            :name => "Name",
            :'parent.id' => "c617c2813a222a34",
            :'service.name' => "My Service",
            :custom_key   => "custom_value"
          }
        }

        assert_equal expected_data, span.to_h
      end
    end
  end
end
