# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    class NilLogger
      %w(debug info warn error fatal unknown).each do |level|
        define_method(level) { |*args| }
        next if level == 'unknown'
        define_method("#{level}?") { false }
      end
    end
  end
end
