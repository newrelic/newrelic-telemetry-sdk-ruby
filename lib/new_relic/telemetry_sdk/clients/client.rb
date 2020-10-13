# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'new_relic/telemetry_sdk/buffer'
require 'new_relic/telemetry_sdk/logger'
require 'new_relic/telemetry_sdk/exception'

module NewRelic
  module TelemetrySdk
    class Client
      include NewRelic::TelemetrySdk::Logger
      
      def initialize host:,
                     path:,
                     headers: {},
                     use_gzip: true,
                     payload_type:
        @connection = set_up_connection host
        @path = path
        @headers = headers
        @gzip_request = use_gzip
        @payload_type = payload_type
        add_content_encoding_header @headers if @gzip_request
        @connection_attempts = 0
        @max_retries= 8 # based on config
        @backoff_factor = 5 # based on config
        @backoff_max = 80 # based on config
      end

      def send_request body
        body = serialize body
        body = gzip_data body if @gzip_request
        @connection.post @path, body, @headers
      end

      def report item
        # Report a batch of one pre-transformed item with no common attributes
        report_batch [[item.to_h], nil]
      end

      def log_and_retry response
        logger.error response.message
        raise NewRelic::TelemetrySdk::ServerConnectionException
      end

      def log_and_retry_later response
        wait_time = response['Retry-After'].to_i 
        logger.error "Connection error. Will attempt to retry in #{wait_time} seconds"
        logger.error response.message
        sleep wait_time
        raise NewRelic::TelemetrySdk::ServerConnectionException
      end

      def log_once_and_drop_data response, data
        log_error_once response.class, response.message
        logger.error "Connection error. Dropping data: #{data.size} points of data"
      end

      def log_and_split_payload response, data, common_attributes
        logger.error "Payload too large. Splitting payload in half and attempting to resend."
        logger.error response.message
        # splits the data in half and calls report_batch for each half
        data1, data2 = data.each_slice((data.size/2.0).round).to_a
        report_batch [data1, common_attributes]
        report_batch [data2, common_attributes]
      end
      
      def log_and_retry_with_backoff response, data
        if @connection_attempts < @max_retries
          wait = backoff_strategy
          logger.error "Connection error. Will attempt to retry in #{wait} seconds."
          logger.error response.message
          sleep wait
          raise NewRelic::TelemetrySdk::ServerConnectionException
        else 
          logger.error "Maximum retries reached. Dropping data: #{data.size} points of data"
        end
      end

      def calculate_backoff_strategy connection_attempts = @connection_attempts, backoff_factor = @backoff_factor, backoff_max = @backoff_max
        [backoff_max, (backoff_factor * (2**(connection_attempts-1)).to_i)].min
      end

      def backoff_strategy
        wait = calculate_backoff_strategy
        @connection_attempts += 1
        wait 
      end

      def report_batch batch_data
        # We need to generate a version 4 uuid that will
        # be used for each unique batch, including on retries.
        # If a batch is split due to a 413 response,
        # each smaller batch should have its own.

        data, common_attributes = batch_data

        @headers[:'x-request-id'] = SecureRandom.uuid

        post_body = format_payload data, common_attributes
      begin
        response = send_request post_body

        case response
        when Net::HTTPSuccess # 200 - 299
          @connection_attempts = 0 # reset count after sucessful connection
        
        when Net::HTTPBadRequest, # 400
            Net::HTTPUnauthorized, # 401
            Net::HTTPForbidden, # 403
            Net::HTTPNotFound, # 404
            Net::HTTPMethodNotAllowed, # 405
            Net::HTTPConflict, # 409
            Net::HTTPGone, # 410
            Net::HTTPLengthRequired  # 411
          log_once_and_drop_data response, data
  
        when Net::HTTPRequestTimeOut # 408
          log_and_retry response

        when Net::HTTPRequestEntityTooLarge # 413
          log_and_split_payload response, data, common_attributes
        
        when Net::HTTPTooManyRequests # 429
          log_and_retry_later response

        else
          log_and_retry_with_backoff response, data
        end

      rescue NewRelic::TelemetrySdk::ServerConnectionException
        retry
      end
      end

      def format_payload data, common_attributes
        post_body = { @payload_type => data }

        if common_attributes
          post_body[:common] = {}
          post_body[:common][:attributes] = common_attributes
        end

        [post_body]
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
