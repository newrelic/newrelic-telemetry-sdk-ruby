# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/telemetry_sdk/clients/client'
require 'securerandom'

module NewRelic
  module TelemetrySdk
    class SpanClient < Client
      def initialize host: 'https://trace-api.newrelic.com'
        super host: host,
              path: '/trace/v1',
               # Note: see whether anything should be sent
               # via query params
              query_params: nil,
              headers: {
                'Content-Type' => 'application/json',
                # Note: should be pulled from configuration when
                # we develop that system
                'Api-Key' => ENV['API_KEY'],
                'Data-Format' => 'newrelic',
                'Data-Format-Version' => '1'
              },
              payload_type: "spans"
      end
    end
  end
end
