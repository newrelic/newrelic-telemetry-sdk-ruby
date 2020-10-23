# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

# Host URL override
#   To facilitate communication with alternative New Relic backends as well as
#   allowing for simple integration testing with a mock backend the SDK should
#   allow each ingest URL to be overridden.

# Failed request retrying
#   It must be possible to configure the backoff factor, that is the amount of time
#     to wait after a failed request before attempting to send the request again.

#   It must also be possible to configure the max retries. See communication backoff.


# Audit logging enabled
#   If audit logging is enabled, the SDK should record additional highly verbose
#   debugging information at the DEBUG logging level. The default value for this
#   setting must be false.

module NewRelic
  module TelemetrySdk
    DEFAULT_HARVEST_INTERVAL = 5

    class Config
      attr_accessor :trace_api_host
      attr_accessor :logger
      attr_accessor :harvest_interval
      attr_accessor :api_insert_key
      attr_accessor :audit_logging_enabled
      attr_accessor :backoff_factor
      attr_accessor :backoff_max
      attr_accessor :max_retries

      def initialize
        @trace_api_host = 'https://trace-api.newrelic.com'
        @logger = Logger.logger
        @harvest_interval = DEFAULT_HARVEST_INTERVAL
        @api_insert_key = ENV[API_INSERT_KEY]
        @audit_logging_enabled = false
        @backoff_factor = 5
        @backoff_max = 80
        @max_retries = 8
      end
    end
  end
end
