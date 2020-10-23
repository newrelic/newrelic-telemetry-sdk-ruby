# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../../..','test_helper'))
require 'new_relic/telemetry_sdk/clients/client'

module NewRelic
  module TelemetrySdk
    class ClientTest < Minitest::Test

      class ItemStub
        def to_h
          { "key" => "data" }
        end
      end

      def setup
        @connection = stub
        @client = Client.new(host: 'host', path: 'path', payload_type: :spans)
        @client.instance_variable_set(:@connection, @connection)
        @client.logger = ::Logger.new(@log_output = StringIO.new)
        @item = ItemStub.new
      end

      def teardown
        Configurator.reset
      end

      # Stubs sleep in the client and expects it to never be called
      def never_sleep
        @sleep = @client.stubs(:sleep)
        @sleep.never
      end

      def log_output
        @log_output.rewind
        @log_output.read
      end

      def client_headers
        @client.instance_variable_get("@headers")
      end

      def stub_server status, message = 'default message', headers = {}
        response = stub_response status, message, headers
        @connection.expects(:post).returns response
      end

      def stub_response status, message = 'default message', headers = {}
        code = status.to_s
        response = Net::HTTPResponse::CODE_TO_OBJ[code].new '1.1', code, message
        headers.each do |key, value|
          response.add_field key, value
        end
        response
      end

      # We should be using the common format for payloads as described here:
      # https://github.com/newrelic/newrelic-telemetry-sdk-specs/blob/master/communication.md#payload
      def test_format_payload
        data = ['Something', 'Somethingelse']
        common_attributes = {:foo => "bar"}

        expected = [
          {
            :common => {
              :attributes => {
                  :foo => "bar"
                }
            },
            :spans => ['Something', 'Somethingelse']
          }
        ]

        payload = @client.send(:format_payload, data, common_attributes)
        assert_equal expected, payload
      end

      def test_status_ok
        NewRelic::TelemetrySdk.configure do |config|
          config.logger = @client.logger
          config.log_level = 'debug'
        end

        never_sleep
        stub_server(200).once

        @client.report @item
        assert_match "Successfully sent data to New Relic with response: 200", log_output
      end

      def test_status_not_found
        never_sleep
        stub_server(404, "not found").once
        @client.report @item
        assert_match "not found", log_output
      end

      def test_status_request_timeout
        never_sleep
        # Returns 408 once and then 200 once, expects exactly 2 calls
        stub_server(408).then.returns(stub_response 200).times(2)
        @client.report @item
      end

      def test_user_agent_header_basics
        assert_match(/^NewRelic-Ruby-TelemetrySDK\/[\d|\.]+$/, client_headers[:'User-Agent'])
        @client.add_user_agent_product "foo"
        assert_match(/^NewRelic-Ruby-TelemetrySDK\/[\d|\.]+\sfoo$/, client_headers[:'User-Agent'])
        @client.add_user_agent_product "bar", "5.0"
        assert_match(/^NewRelic-Ruby-TelemetrySDK\/[\d|\.]+\sfoo\sbar\/5\.0$/, client_headers[:'User-Agent'])
      end

      def test_user_agent_header_rejects_invalid_product_token
        @client.add_user_agent_product "(foo)" # parentheses not allowed!
        assert_match(/^NewRelic-Ruby-TelemetrySDK\/[\d|\.]+$/, client_headers[:'User-Agent'])
      end

      def test_user_agent_header_ignores_invalid_product_version_token
        @client.add_user_agent_product "foo", "(5.0)" # parentheses not allowed!
        assert_match(/^NewRelic-Ruby-TelemetrySDK\/[\d|\.]+\sfoo$/, client_headers[:'User-Agent'])
      end

      def test_user_agent_header_double_entry_ignored
        @client.add_user_agent_product "bar", "5.0"
        @client.add_user_agent_product "bar", "5.0"
        assert_match(/^NewRelic-Ruby-TelemetrySDK\/[\d|\.]+\sbar\/5\.0$/, client_headers[:'User-Agent'])
      end


      def test_status_request_entity_too_large_splittable
        never_sleep
        # payload too large, then splits and stubs 200 response for each half
        stub_server(413).then.returns(stub_response 200).then.returns(stub_response 200).times(3)
        @client.report_batch [[@item, @item], nil]
      end

      def test_status_request_entity_too_large_not_splittable
        never_sleep
        # payload too large, then splits and stubs 200 response for each half
        stub_server(413).once
        @client.report @item
      end

      def test_status_request_too_many_requests
        sleep_time = 42
        # expects it to wait the given amount of seconds
        @client.expects(:sleep).with(sleep_time).once
        # Returns 429 once (with the amount of seconds to wait before trying again) and then 200 once, expects exactly 2 calls
        stub_server(429, 'with Retry-After', { 'Retry-After' => sleep_time }).then.returns(stub_response 200).times(2)
        @client.report @item
      end

      def test_status_server_error
        sleep_time = 42
        # makes sure that it is sleeping for the amount of time returned by the backoff calculation
        @client.expects(:calculate_backoff_strategy).then.returns(sleep_time).once
        @client.expects(:sleep).with(sleep_time).once

        stub_server(500).then.returns(stub_response 200).times(2)

        @client.report @item
      end

      def test_backoff_calculation
        # example numbers from the spec
        expected =  [0, 1, 2, 4, 8, 16, 16, 16]
        NewRelic::TelemetrySdk.configure do |config|
          config.backoff_max = 16
          config.backoff_factor = 1
        end

        (0..7).each do |attempt|
          @client.instance_variable_set :'@connection_attempts', attempt
          assert_equal expected[attempt], @client.send(:calculate_backoff_strategy)
        end

        # more examples from the spec
        expected =  [0, 5, 10, 20, 40, 80, 80, 80]
        NewRelic::TelemetrySdk.configure do |config|
          config.backoff_max = 80
          config.backoff_factor = 5
        end

        (0..7).each do |attempt|
          @client.instance_variable_set :'@connection_attempts', attempt
          assert_equal expected[attempt], @client.send(:calculate_backoff_strategy)
        end
      end

      def test_backoff_strategy_increments_attempts
        time = 13
        @client.expects(:calculate_backoff_strategy).then.returns(time).once
        attempts = @client.instance_variable_get(:@connection_attempts)
        assert_equal time, @client.send(:backoff_strategy)
        assert_equal attempts+1, @client.instance_variable_get(:@connection_attempts)
      end

      def test_raises_before_max_retries
        @client.expects(:backoff_strategy).then.returns(0).once
        @client.instance_variable_set(:@max_retries, 5)
        @client.instance_variable_set(:@connection_attempts, 4)
        # Retry raises an exception, so we want the exception raised here
        assert_raises NewRelic::TelemetrySdk::RetriableServerResponseException do
          @client.send(:log_and_retry_with_backoff, stub_response(413), [mock])
        end
      end

      def test_reaching_max_attempts_stops_retrying
        NewRelic::TelemetrySdk.configure do |config|
          config.max_retries = 5
        end

        @client.instance_variable_set(:@max_retries, 5)
        @client.instance_variable_set(:@connection_attempts, 5)
        # Retrying raises an exception, so we want to make sure there is no exception raised here
        @client.send(:log_and_retry_with_backoff, stub_response(413), [mock])
      end

      def test_splitting_payload
        common = [test: 'test']
        data = [1, 2, 3, 4]
        @client.expects(:report_batch).with([[1,2],common])
        @client.expects(:report_batch).with([[3,4],common])
        @client.send(:log_and_split_payload, stub_response(413), data, common)
      end

      def test_splitting_odd_payload
        common = [test: 'test']
        data = [1, 2, 3, 4, 5]
        @client.expects(:report_batch).with([[1,2,3],common])
        @client.expects(:report_batch).with([[4,5],common])
        @client.send(:log_and_split_payload, stub_response(413), data, common)
      end

      def test_splitting_payload_of_one
        common = [test: 'test']
        data = []
        @client.expects(:report_batch).never
        @client.send(:log_and_split_payload, stub_response(413), data, common)
      end

      def test_report_batch_never_raises_error
        @client.stubs(:format_payload).raises(StandardError.new('pretend_error'))
        # if an error bubbles up here, test fails
        @client.report_batch [[@item, @item], nil]
        assert_match(/Encountered error./, log_output)
        assert_match(/pretend_error/, log_output)
      end

      def test_report_never_raises_error
        @client.stubs(:report_batch).raises(StandardError.new('pretend_error'))
        # if an error bubbles up here, test fails
        @client.report @item
        assert_match(/Encountered error./, log_output)
        assert_match(/pretend_error/, log_output)
      end

      def test_audit_logging
        NewRelic::TelemetrySdk.configure do |config|
          config.audit_logging_enabled = true
          config.logger = @client.logger
          config.log_level = 'debug'
        end

        stub_server(200, "OK").once
        @client.report @item
        assert_match "Sent payload: [{\"spans\":[{\"key\":\"data\"}]}]", log_output
      end
    end
  end
end
