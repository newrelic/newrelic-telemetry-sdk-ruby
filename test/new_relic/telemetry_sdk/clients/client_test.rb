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
        @sleep = @client.stubs(:sleep)
        @item = ItemStub.new
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
        @sleep.never
        stub_server(200).once

        @client.report @item
      end

      def test_status_not_found
        @sleep.never
        stub_server(404).once
        @client.report @item
      end
      
      def test_status_request_timeout
        @sleep.never
        stub_server(408).once
        @client.report @item
      end

      def test_status_request_entity_too_large
        @sleep.never
        stub_server(413).once
        @client.report @item
      end

      def test_status_request_too_many_requests
        @sleep.never
        stub_server(429).once
        @client.report @item
      end

      def test_status_server_error
        @sleep.never
        stub_server(500).once
        @client.report @item
      end

      def stub_server status, message = 'default message'
        response = stub_response status, message
        @connection.stubs(:post).returns response
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
