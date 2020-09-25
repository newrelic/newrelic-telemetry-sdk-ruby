# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'new_relic/telemetry_sdk/batch'
require 'new_relic/telemetry_sdk/span'

module NewRelic
  module TelemetrySdk
    class BatchTest < Minitest::Test
      def setup
        @batch = Batch.new
      end

      def test_record
        span = Span.new
        @batch.record span

        assert_equal 1, @batch.items.length
      end

      def test_flush
        span = Span.new
        @batch.record span

        data, _ = @batch.flush

        assert_equal 1, data.length
      end

      def test_common_attributes
        common_attributes = { :foo => "bar" }
        @batch_with_common_attributes = Batch.new common_attributes

        _, actual = @batch_with_common_attributes.flush

        assert_equal common_attributes, actual
      end
    end
  end
end
