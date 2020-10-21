# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk

    def self.configure
      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    end
    
    class Configurator

      attr_writer :logger

      def initialize
        @logger = Logger.logger
      end

      def configure
        Logger.logger = @logger
      end
    end
  end
end
