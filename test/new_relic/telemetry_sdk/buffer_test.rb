# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'new_relic/telemetry_sdk/buffer'
require 'new_relic/telemetry_sdk/span'

module NewRelic
  module TelemetrySdk
    class BufferTest < Minitest::Test
      def setup
        @buffer = Buffer.new
      end

      def test_record
        span = Span.new
        @buffer.record span

        assert_equal 1, @buffer.items.length
      end

      def test_flush
        span = Span.new
        @buffer.record span

        data, _ = @buffer.flush

        assert_equal 1, data.length
        assert_equal 0, @buffer.items.length
      end

      def test_common_attributes
        expected = { :foo => "bar" }

        @buffer_with_common_attributes = Buffer.new expected
        actual = @buffer_with_common_attributes.common_attributes

        assert_equal expected, actual
      end
    end
  end
end
