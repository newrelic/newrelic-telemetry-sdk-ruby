# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk

    # Set Telemetry SDK configuration with a block.
    # See NewRelic::TelemetrySdk::Config for options.
    #
    # Example:
    # NewRelic::TelemetrySdk.configure do |config|
    #   config.api_insert_key = ENV["API_KEY"]
    # end
    #
    # @api public
    def self.configure
      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    end

    def self.config
      Configurator.config
    end

    class Configurator
      def self.config
        @config ||= Config.new
      end

      def self.reset
        @config = nil
      end

      def config
        Configurator.config
      end

      # passes any setter methods to the Config object if it responds to such.
      # all other missing methods are propagated up the chain.
      def method_missing method, *args, &block
        if method.to_s =~ /\=$/ && config.respond_to?(method)
          config.send method, *args, &block
        else
          super
        end
      end

      def configure
        Logger.logger = config.logger
      end
    end
  end
end
