# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))
require "logger"

module NewRelic
  module TelemetrySdk
    class ConfiguratorTest < Minitest::Test
      class FakeClient
        include Logger
      end

      def setup
        @fake_client = FakeClient.new
        @log_output = StringIO.new
      end

      def log_output
        @log_output.rewind
        @log_output.read
      end

      def test_configure_client_logger
        NewRelic::TelemetrySdk.configure do |config|
          config.logger = ::Logger.new(@log_output)
        end
        @fake_client.logger.warn "FIRST"
        @fake_client.logger.warn "SECOND"
        assert_match "FIRST", log_output
        assert_match "SECOND", log_output
      end

      def test_configure_global_logger
        NewRelic::TelemetrySdk.configure do |config|
          config.logger = ::Logger.new(@log_output)
        end
        @fake_client.logger.warn "FIRST"
        NewRelic::TelemetrySdk.logger.warn "SECOND"
        assert_match "FIRST", log_output
        assert_match "SECOND", log_output
      end
    end
  end
end
