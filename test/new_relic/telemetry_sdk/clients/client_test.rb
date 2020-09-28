# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../../..','test_helper'))
require 'new_relic/telemetry_sdk/clients/client'
require 'json'

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
        @client = Client.new(host: 'host', path: 'path', payload_type: 'spans')
        @client.instance_variable_set(:@connection, @connection)
        @sleep = @client.stubs(:sleep)
        @item = ItemStub.new
      end

      def test_status_ok
        @sleep.never
        stub_server(200).once

        @client.report [@item.to_h]
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
