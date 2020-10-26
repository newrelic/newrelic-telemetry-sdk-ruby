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

      def teardown
        Configurator.reset
        Logger.logger = nil
      end

      def log_output
        @log_output.rewind
        @log_output.read
      end

      def test_method_missing_delegator
        NewRelic::TelemetrySdk.configure do |config|
          assert_raises(NoMethodError) { config.api_key }
        end
      end

      def test_configure_nil_logger
        NewRelic::TelemetrySdk.configure do |config|
          config.logger = NewRelic::TelemetrySdk::NilLogger.new
        end
        assert @fake_client.logger.is_a? NewRelic::TelemetrySdk::NilLogger
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

      def test_configure_harvest_interval
        NewRelic::TelemetrySdk.configure do |config|
          config.harvest_interval = 10
        end
        harvester = Harvester.new 
        assert_equal 10, harvester.interval
      end

      def test_configure_client_api_key
        NewRelic::TelemetrySdk.configure do |config|
          config.api_insert_key = "AN_ORDINARY_KEY"
        end
        span_client = NewRelic::TelemetrySdk::SpanClient.new
        assert_equal "AN_ORDINARY_KEY", span_client.api_insert_key
      end

      def test_configure_trace_api_host
        NewRelic::TelemetrySdk.configure do |config|
          config.trace_api_host = "localhost"
        end
        NewRelic::TelemetrySdk::SpanClient.any_instance.expects(:set_up_connection).with("localhost")
        # causes `set_up_connection` to be invoked
        NewRelic::TelemetrySdk::SpanClient.new
      end

    end
  end
end
