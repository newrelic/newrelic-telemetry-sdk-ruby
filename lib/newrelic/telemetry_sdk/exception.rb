# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    # A {RetriableServerResponseException} is used to signal that the SDK
    # should attempt to resend the data that received a response error
    # from the server on the previous attempt.
    # @private
    class RetriableServerResponseException < StandardError; end
  end
end