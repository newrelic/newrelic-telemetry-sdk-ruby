# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require_relative 'client'

module NewRelic
  module TelemetrySdk
    class SpanClient < Client
      def initialize host: 'https://trace-api.newrelic.com'
        super host: host,
              path: '/trace/v1',
              headers: {
                :'Content-Type' => 'application/json',
                # Note: should be pulled from configuration when
                # we develop that system
                :'Api-Key' => api_insert_key,
                :'Data-Format' => 'newrelic',
                :'Data-Format-Version' => '1'
              },
              payload_type: :spans
      end
    end
  end
end
