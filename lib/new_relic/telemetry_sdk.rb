# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.

require 'net/http'
require 'json'
require 'zlib'
require 'securerandom'
require 'logger'

module NewRelic
  module TelemetrySdk
    USER_AGENT_NAME = "NewRelic-Ruby-TelemetrySDK"
    RFC7230_TOKEN = /^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$/
  end
end

require 'new_relic/telemetry_sdk/version'
require 'new_relic/telemetry_sdk/util'

require 'new_relic/telemetry_sdk/span'
require 'new_relic/telemetry_sdk/harvester'
require 'new_relic/telemetry_sdk/buffer'

require 'new_relic/telemetry_sdk/clients/client'
require 'new_relic/telemetry_sdk/clients/span_client'
