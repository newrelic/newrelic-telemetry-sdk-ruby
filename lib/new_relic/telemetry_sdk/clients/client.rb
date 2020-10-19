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
        @user_agent_products = nil
        add_user_agent_header @headers
        add_content_encoding_header @headers if @gzip_request
        @connection_attempts = 0
        @max_retries= 8 # based on config
        @backoff_factor = 5 # based on config
        @backoff_max = 80 # based on config
      end

      def report item
        # Report a batch of one pre-transformed item with no common attributes
        report_batch [[item.to_h], nil]
      rescue => e
        logger.error e.to_s
        logger.error "Encountered error. Dropping data: 1 point of data"
      end

      def report_batch batch_data
        # We need to generate a version 4 uuid that will
        # be used for each unique batch, including on retries.
        # If a batch is split due to a 413 response,
        # each smaller batch should have its own.

        data, common_attributes = batch_data

        @headers[:'x-request-id'] = SecureRandom.uuid

        post_body = format_payload data, common_attributes
        send_with_response_handling post_body, data, common_attributes
      rescue => e
        logger.error "Encountered error. Dropping data: #{data.size} points of data"
        logger.error e
      end

      def add_user_agent_product product, version=nil
        # The product token must be valid to add to the headers
        if product !~ RFC7230_TOKEN
          log_once :warn, "Product is not a valid RFC 7230 token"
          return
        end

        # The version is ignored if invalid
        if version && version !~ RFC7230_TOKEN
          log_once :warn, "Product version is not a valid RFC 7230 token"
          version = nil
        end

        entry = [product, version].compact.join("/")

        # adds the product entry and updates the combined user agent 
        # header, ignoring duplicate product entries.
        @user_agent_products ||= []
        unless @user_agent_products.include? entry
          @user_agent_products << entry
          add_user_agent_header @headers
        end
      rescue => e
        logger.error "Encountered error adding user agent product"
        logger.error e
      end

    private

      def send_with_response_handling post_body, data, common_attributes
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

      rescue NewRelic::TelemetrySdk::RetriableServerResponseException
        retry
      end
      
      def send_request body
        body = serialize body
        body = gzip_data body if @gzip_request
        @connection.post @path, body, @headers
      end

      def log_and_retry response
        logger.error response.message
        raise NewRelic::TelemetrySdk::RetriableServerResponseException
      end

      def log_and_retry_later response
        wait_time = response['Retry-After'].to_i 
        logger.error "Connection error. Retrying in #{wait_time} seconds"
        logger.error response.message
        sleep wait_time
        raise NewRelic::TelemetrySdk::RetriableServerResponseException
      end

      def log_once_and_drop_data response, data
        log_error_once response.class, response.message
        logger.error "Connection error. Dropping data: #{data.size} points of data"
      end

      def log_and_split_payload response, data, common_attributes
        logger.error "Payload too large. Splitting payload in half and attempting to resend."
        logger.error response.message
        if data.size > 1
          # splits the data in half and calls report_batch for each half
          midpoint = data.size/2.0
          report_batch [data.first(midpoint.ceil), common_attributes]
          report_batch [data.last(midpoint.floor), common_attributes]
        else 
          # payload cannot be split, drop data
          logger.error "Unable to split payload. Dropping data: #{data.size} points of data"
        end
      end
      
      def log_and_retry_with_backoff response, data
        if @connection_attempts < @max_retries
          wait = backoff_strategy
          logger.error "Connection error. Retrying in #{wait} seconds."
          logger.error response.message
          sleep wait
          raise NewRelic::TelemetrySdk::RetriableServerResponseException
        else 
          logger.error "Maximum retries reached. Dropping data: #{data.size} points of data"
        end
      end

      def calculate_backoff_strategy connection_attempts = @connection_attempts, 
                                     backoff_factor = @backoff_factor, 
                                     backoff_max = @backoff_max
        [backoff_max, (backoff_factor * (2**(connection_attempts-1)).to_i)].min
      end

      def backoff_strategy
        wait = calculate_backoff_strategy
        @connection_attempts += 1
        wait 
      end

      def format_payload data, common_attributes
        post_body = { @payload_type => data }

        if common_attributes
          post_body[:common] = {}
          post_body[:common][:attributes] = common_attributes
        end

        [post_body]
      end

      def add_user_agent_header headers
        sdk_id = "#{USER_AGENT_NAME}/#{VERSION}"
        headers[:'User-Agent'] = ([sdk_id] + Array(@user_agent_products)).join(" ")
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
