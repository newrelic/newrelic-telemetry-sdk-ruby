# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'net/http'
require 'json'
require 'zlib'
require 'securerandom'

require 'new_relic/telemetry_sdk/batch'

module NewRelic
  module TelemetrySdk
    class Client
      def initialize host:,
                     path:,
                     headers: {},
                     use_gzip: true,
                     payload_type:
        @connection = set_up_connection host
        @path = path
        @headers = headers
        @gzip_request = use_gzip
        add_content_encoding_header @headers if @gzip_request
        @payload_type = payload_type
      end

      def send_request body
        body = serialize body
        body = gzip_data body if @gzip_request
        @connection.post @path, body, @headers
      end

      def report item
        batch = Batch.new
        batch.record item
        report_batch batch
      end

      def report_batch batch
        # We need to generate a version 4 uuid that will
        # be used for each unique batch, including on retries.
        # If a batch is split due to a 413 response,
        # each smaller batch should have its own.
        @headers[:'x-request-id'] = SecureRandom.uuid

        post_body = { @payload_type => batch.to_h }

        if defined? batch.common_attributes
          post_body[:common] = {}
          post_body[:common][:attributes] = batch.common_attributes
        end

        response = send_request [post_body]

        return if response.is_a? Net::HTTPSuccess
        # Otherwise, take appropriate action based on response code
      end

      def add_content_encoding_header headers
        headers.merge!(:'content-encoding' => 'gzip')
      end

      def set_up_connection host
        uri = URI(host)
        conn = Net::HTTP.new uri.host, uri.port
        conn.use_ssl = true
        conn
      end

      def serialize data
        JSON.generate data
      end

      def gzip_data data
        Zlib.gzip data
      end
    end
  end
end
