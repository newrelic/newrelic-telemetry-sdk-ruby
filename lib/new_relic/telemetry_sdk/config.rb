# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    DEFAULT_HARVEST_INTERVAL = 5

    class Config
      attr_accessor :logger
      attr_accessor :harvest_interval
      attr_accessor :api_insert_key

      def initialize
        @logger = Logger.logger
        @harvest_interval = DEFAULT_HARVEST_INTERVAL
        @api_insert_key = ENV[API_INSERT_KEY]
      end
    end
  end
end
