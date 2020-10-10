# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../../..','test_helper'))
require 'new_relic/telemetry_sdk/clients/client'
require 'logger'

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

      # Stups sleep in the client and expects it to never be called
      def never_sleep 
        @sleep = @client.stubs(:sleep)
        @sleep.never
      end

      def log_output
        @log_output.rewind
        @log_output.read
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

        payload = @client.format_payload(data, common_attributes)
        assert_equal expected, payload
      end

      def test_status_ok
        never_sleep
        stub_server(200).once

        @client.report @item
      end

      def test_status_not_found
        never_sleep
        stub_server(404, "not found").once
        @client.report @item
        assert_match "not found", log_output
      end
      
      def test_status_request_timeout
        never_sleep
        # Returns 208 once and then 200 once, expects exactly 2 calls
        stub_server(408).then.returns(stub_response 200).times(2)
        @client.report @item
      end

      def test_status_request_entity_too_large
        never_sleep
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
        # TODO: should retry based on backoff strategy
        never_sleep
        stub_server(500).once
        @client.report @item
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
    end
  end
end
