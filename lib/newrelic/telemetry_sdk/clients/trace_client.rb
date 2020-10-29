# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require_relative 'client'

module NewRelic
  module TelemetrySdk
    class TraceClient < Client
      def initialize host: trace_api_host
        super host: host,
              path: '/trace/v1',
              headers: {
                :'Content-Type' => 'application/json',
                :'Api-Key' => api_insert_key,
                :'Data-Format' => 'newrelic',
                :'Data-Format-Version' => '1'
              },
              payload_type: :spans
      end

      def trace_api_host
        TelemetrySdk.config.trace_api_host
      end
    end
  end
end
