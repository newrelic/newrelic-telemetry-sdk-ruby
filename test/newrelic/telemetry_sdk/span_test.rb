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
        assert span.contents[:id].is_a? String
        assert span.contents[:trace_id].is_a? String
        assert span.contents[:timestamp].is_a? Integer

        expected_attributes = {
          :name=>"Name",
          :duration=>nil,
          :parent_id=>nil,
          :service_name=>nil
        }

        assert_equal expected_attributes, span.contents[:attributes]

        # Note: should this go in recommended attributes?
        # It is recommended from the point of view of the
        # Trace API but at least some Telemetry SDK implementations
        # do require it on span creation.
        assert_equal "Name", span.contents[:attributes][:name]
        assert span.contents[:attributes][:name].is_a? String
      end

      def test_recommended_attributes
        span = Span.new("Name",
                        duration: 123456,
                        parent_id: "c617c2813a222a34",
                        service_name: "My Service")

        expected_attributes = {
          :name=>"Name",
          :duration=>123456,
          :parent_id=>"c617c2813a222a34",
          :service_name=>"My Service"
        }

        assert_equal expected_attributes, span.contents[:attributes]

        assert_equal 123456, span.contents[:attributes][:duration]
        assert span.contents[:attributes][:duration].is_a? Integer

        assert_equal "c617c2813a222a34", span.contents[:attributes][:parent_id]
        assert span.contents[:attributes][:parent_id].is_a? String

        assert_equal "My Service", span.contents[:attributes][:service_name]
        assert span.contents[:attributes][:service_name].is_a? String
      end

      def test_custom_attributes
        custom_attributes = {
          :'user.email' => "me@newr.com",
          :something  => "somethingelse"
        }

        span = Span.new("Name", custom_attributes: custom_attributes)

        expected_attributes = {
          :name=>"Name",
          :duration=>nil,
          :parent_id=>nil,
          :service_name=>nil,
          :'user.email'=>"me@newr.com",
          :something=>"somethingelse"
        }

        assert_equal expected_attributes, span.contents[:attributes]
      end

      def test_finish
        start_time = Util.time_to_ms
        span = Span.new("Name", timestamp: start_time)

        # Mock a span that took 3 seconds
        end_time = start_time + 3000
        span.finish(end_time_ms: end_time)

        assert_equal 3000, span.contents[:duration]
      end
    end
  end
end
