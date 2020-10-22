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
    
    def self.config
      Configurator.config
    end

    class Configurator
      def self.config= config
        @config = config
      end
    
      def self.config
        @config ||= Config.new
      end

      def self.reset
        @config = nil
      end

      def config
        Configurator.config
      end

      def logger= logger
        config.logger = logger
      end

      def harvest_interval= interval
        config.harvest_interval = interval
      end

      def configure
        Logger.logger = config.logger
      end       
    end
  end
end
