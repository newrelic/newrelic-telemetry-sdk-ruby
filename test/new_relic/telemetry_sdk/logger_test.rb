# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))
require "logger"

module NewRelic
  module TelemetrySdk
    class LoggerTest < Minitest::Test
      class FakeClient
        include Logger
      end

      def setup
        @fake_client = FakeClient.new
        @log_output = StringIO.new
        @fake_client.logger = ::Logger.new(@log_output)
      end

      def log_output
        @log_output.rewind
        @log_output.read
      end

      def test_log
        @fake_client.logger.warn "FIRST"
        @fake_client.logger.warn "SECOND"
        assert_match "FIRST", log_output
        assert_match "SECOND", log_output
      end

      # Level plays no role in logging once!  This test demonstrates that.
      def test_log_once
        @fake_client.log_once :warn, :foo, "FIRST"
        @fake_client.log_once :error, :foo, "SECOND"
        assert_match "FIRST", log_output
        refute_match "SECOND", log_output
      end

      def test_warn_once
        @fake_client.log_warn_once :foo, "FIRST"
        @fake_client.log_warn_once :foo, "SECOND"
        assert_match "WARN", log_output
        assert_match "FIRST", log_output
        refute_match "SECOND", log_output
      end

      def test_all_the_levels_once
        @fake_client.log_debug_once :one, "FIRST"
        @fake_client.log_warn_once :two, "SECOND"
        @fake_client.log_error_once :three, "THIRD"
        @fake_client.log_info_once :four, "FOURTH"
        @fake_client.log_fatal_once :five, "FIFTH"
        assert_match "FIRST", log_output
        assert_match "SECOND", log_output
        assert_match "THIRD", log_output
        assert_match "FOURTH", log_output
        assert_match "FIFTH", log_output
      end
    end
  end
end
