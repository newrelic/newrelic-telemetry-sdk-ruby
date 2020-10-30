# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    VERSION = "0.1.0"

    extend self

    def gem_version
      Gem::Version.create VERSION
    end
  end
end
