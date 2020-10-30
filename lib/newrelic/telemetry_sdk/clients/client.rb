# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    # This class is a parent class for clients used to send data to the New Relic data
    # ingest endpoints over HTTP (e.g. TraceClient for span data). Clients will automatically
    # resend data if a recoverable error occurs. They will also automatically handle
    # connection issues and New Relic errors.
    #
    # @api public
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
      end

      # Reports a single item to a New Relic data ingest endpoint.
      #
      # @param item
      #     a single point of data to send to New Relic (e.g. a Span). The item
      #     should respond to the +#to_h+ method to return a Hash which is then serialized
      #     and sent to the data ingest endpoint.
      #
      # @api public
      def report item
        # Report a batch of one pre-transformed item with no common attributes
        report_batch [[item.to_h], nil]
      rescue => e
        log_error "Encountered error reporting item in client. Dropping data: 1 point of data", e
      end

      # Reports a batch of one or more items to a New Relic data ingest endpoint.
      #
      # @param batch_data [Array]
      #     a two-part array contianing a Array of Hashes paired with a Hash of
      #     common attributes.
      #
      # @api public
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
        log_error "Encountered error reporting batch in client. Dropping data: #{data.size} points of data", e
      end

      # Allows creators of exporters and other product built on this SDK to provide information about
      # their product for analytic purposes.  It may be called multiple times and is idempotent.
      #
      # @param product [String]
      #     The name of the exporter or other product, e.g. NewRelic-Ruby-OpenTelemetry.
      # @param version [optional, String]
      #     The version number of the exporter or other product.
      #
      # Both product and version must conform to RFC 7230.
      # @see https://github.com/newrelic/newrelic-telemetry-sdk-specs/blob/master/communication.md#extending-user-agent-with-exporter-product
      #
      # @api public
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
        log_error "Encountered error adding user agent product", e
      end

    private

      def api_insert_key
        TelemetrySdk.config.api_insert_key
      end

      def max_retries
        TelemetrySdk.config.max_retries
      end

      def backoff_factor
        TelemetrySdk.config.backoff_factor
      end

      def backoff_max
        TelemetrySdk.config.backoff_max
      end

      def send_with_response_handling post_body, data, common_attributes
        response = send_request post_body

        case response
        when Net::HTTPSuccess # 200 - 299
          @connection_attempts = 0 # reset count after sucessful connection
          logger.debug "Successfully sent data to New Relic with response: #{response.code}"

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

      def audit_logging_enabled?
        TelemetrySdk.config.audit_logging_enabled
      end

      def send_request body
        body = serialize body
        log_json_payload body if audit_logging_enabled?
        body = gzip_data body if @gzip_request
        @connection.post @path, body, @headers
      end

      def log_json_payload payload
        logger.debug "Sent payload: #{payload}"
      end

      def log_and_retry response
        log_error response.message
        raise NewRelic::TelemetrySdk::RetriableServerResponseException
      end

      def log_and_retry_later response
        wait_time = response['Retry-After'].to_i
        log_error "Connection error. Retrying in #{wait_time} seconds", response.message
        sleep wait_time
        raise NewRelic::TelemetrySdk::RetriableServerResponseException
      end

      def log_once_and_drop_data response, data
        log_error_once response.class, response.message
        log_error "Connection error. Dropping data: #{data.size} points of data"
      end

      def log_and_split_payload response, data, common_attributes
        log_error "Payload too large. Splitting payload in half and attempting to resend.", response.message
        if data.size > 1
          # splits the data in half and calls report_batch for each half
          midpoint = data.size/2.0
          report_batch [data.first(midpoint.ceil), common_attributes]
          report_batch [data.last(midpoint.floor), common_attributes]
        else
          # payload cannot be split, drop data
          log_error "Unable to split payload. Dropping data: #{data.size} points of data"
        end
      end

      def log_and_retry_with_backoff response, data
        if @connection_attempts < max_retries
          wait = backoff_strategy
          log_error "Connection error. Retrying in #{wait} seconds.", response.message
          sleep wait
          raise NewRelic::TelemetrySdk::RetriableServerResponseException
        else
          log_error "Maximum retries reached. Dropping data: #{data.size} points of data"
        end
      end

      def calculate_backoff_strategy
        [backoff_max, (backoff_factor * (2**(@connection_attempts-1)).to_i)].min
      end

      def backoff_strategy
        calculate_backoff_strategy.tap { @connection_attempts += 1 }
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
