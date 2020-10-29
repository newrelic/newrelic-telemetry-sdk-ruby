# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    DEFAULT_TRACE_API_HOST = "https://trace-api.newrelic.com"
    DEFAULT_HARVEST_INTERVAL = 5
    DEFAULT_BACKOFF_FACTOR = 5
    DEFAULT_BACKOFF_MAX = 80
    DEFAULT_MAX_RETRIES = 8

    # This class allows setting configuration options for the Telemetry SDK
    # via NewRelic::TelemetrySdk.configure.
    #
    # Configuration options are as follows:
    #
    # api_insert_key [optional, String]
    #     A New Relic Insert API key. Necessary for sending data to
    #     New Relic via the Telemetry SDK. Defaults to +API_INSERT_KEY+
    #     environment variable.
    #     @see https://docs.newrelic.com/docs/apis/get-started/intro-apis/types-new-relic-api-keys#event-insert-key
    # logger [optional, Logger]
    #     A Logger object customized with your preferred log output
    #     destination (if any) and log level.
    # audit_logging_enabled [optional, Boolean]
    #     If audit logging is enabled, the contents of every payload
    #     sent to New Relic will be recorded in logs.
    #     This is a very verbose log level for debugging purposes.
    # harvest_interval [optional, Integer]
    #     The frequency of automatic harvest (in seconds) if sending data
    #     with a harvester.
    #     Defaults to 5 seconds.
    # backoff_factor [optional, Integer]
    #     The amount of time (in seconds) to wait after sending data
    #     to New Relic fails before attempting to send again.
    #     Defaults to 5 seconds.
    # backoff_max [optional, Integer]
    #     If data cannot be sent to New Relic intermittently, the SDK will
    #     retry the request at increasing intervals, but will stop increasing
    #     the retry intervals when they have reached +backoff_max+ seconds.
    #     Defaults to 80 seconds.
    #     @see https://github.com/newrelic/newrelic-telemetry-sdk-specs/blob/master/communication.md#graceful-degradation
    # max_retries [optional, Integer]
    #     The maximum number of times to retry sending data to New Relic.
    #     Defaults to 8.
    # trace_api_host [optional, String]
    #     An alternative New Relic host URL where spans can be sent.
    #
    # @api public
    class Config
      attr_accessor :api_insert_key
      attr_accessor :logger
      attr_accessor :audit_logging_enabled
      attr_accessor :harvest_interval
      attr_accessor :backoff_factor
      attr_accessor :backoff_max
      attr_accessor :max_retries
      attr_accessor :trace_api_host

      def initialize
        @api_insert_key = ENV[API_INSERT_KEY]
        @logger = Logger.logger
        @audit_logging_enabled = false

        @harvest_interval = DEFAULT_HARVEST_INTERVAL
        @backoff_factor = DEFAULT_BACKOFF_FACTOR
        @backoff_max = DEFAULT_BACKOFF_MAX
        @max_retries = DEFAULT_MAX_RETRIES
        @trace_api_host = DEFAULT_TRACE_API_HOST
      end
    end
  end
end
