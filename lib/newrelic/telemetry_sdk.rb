# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require 'net/http'
require 'logger'
require 'json'
require 'zlib'
require 'securerandom'
require 'logger'

module NewRelic
  module TelemetrySdk
    USER_AGENT_NAME = "NewRelic-Ruby-TelemetrySDK"
    RFC7230_TOKEN = /^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$/

    # Environment variable names
    NEW_RELIC_PREFIX = "NEW_RELIC"
    API_INSERT_KEY = "#{NEW_RELIC_PREFIX}_API_INSERT_KEY"
  end
end

require 'newrelic/telemetry_sdk/version'
require 'newrelic/telemetry_sdk/util'
require 'newrelic/telemetry_sdk/exception'

require 'newrelic/telemetry_sdk/config'
require 'newrelic/telemetry_sdk/configurator'
require 'newrelic/telemetry_sdk/logger'

require 'newrelic/telemetry_sdk/span'
require 'newrelic/telemetry_sdk/harvester'
require 'newrelic/telemetry_sdk/buffer'

require 'newrelic/telemetry_sdk/clients/client'
require 'newrelic/telemetry_sdk/clients/trace_client'
