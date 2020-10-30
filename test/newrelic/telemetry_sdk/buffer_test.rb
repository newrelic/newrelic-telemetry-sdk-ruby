# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

module NewRelic
  module TelemetrySdk
    class BufferTest < Minitest::Test
      def setup
        @buffer = Buffer.new
        @buffer.logger = ::Logger.new(@log_output = StringIO.new)

      end

      def log_output
        @log_output.rewind
        @log_output.read
      end
      
      def test_record
        span = Span.new
        @buffer.record span

        assert_equal 1, @buffer.instance_variable_get(:@items).length
      end

      def test_flush
        span = Span.new
        @buffer.record span

        data, _ = @buffer.flush

        assert_equal 1, data.length
        assert_equal 0, @buffer.instance_variable_get(:@items).length
      end

      def test_common_attributes
        expected = { :foo => "bar" }

        @buffer_with_common_attributes = Buffer.new expected
        actual = @buffer_with_common_attributes.common_attributes

        assert_equal expected, actual
      end

      def test_flush_logs_error
        @buffer.instance_variable_get(:@lock).stubs(:synchronize).raises(StandardError.new('pretend_error'))
        @buffer.flush
        assert_match(/pretend_error/, log_output)
      end

      def test_record_logs_error
        @buffer.instance_variable_get(:@lock).stubs(:synchronize).raises(StandardError.new('pretend_error'))
        @buffer.record(stub)
        assert_match(/pretend_error/, log_output)
      end

    end
  end
end
