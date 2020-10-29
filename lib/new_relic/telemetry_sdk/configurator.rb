# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    # The {Configurator} provides the mechanism through which the SDK is configured.
    # 
    # @example
    #   NewRelic::TelemetrySdk.configure do |config|
    #     config.api_insert_key = ENV["API_KEY"]
    #   end
    #
    # See {Config} for details on what properties can be configured.
    #
    # @api public
    class Configurator
      def self.config
        @config ||= Config.new
      end

      # Removes any configurations that were previously customized, effectively
      # resetting the {Config} state to defaults
      #
      # @api private
      def self.reset
        @config = nil
      end

      # Allows direct access to the config state.  The primary purpose of this method is
      # to access config properties throughout the SDK.
      #
      # @note Unlike configuring with # {#self.configure}, setting config properties here 
      #       may, or may not become immediately active.  Use with care.
      #
      # @api public
      def config
        Configurator.config
      end

      # Set Telemetry SDK configuration with a block.
      # See {Config} for options.
      #
      # Example:
      #   NewRelic::TelemetrySdk.configure do |config|
      #     config.api_insert_key = ENV["API_KEY"]
      #   end
      #
      # @api public
      def configure
        Logger.logger = config.logger
      end

      private

      # passes any setter methods to the Config object if it responds to such.
      # all other missing methods are propagated up the chain.
      # @api private
      def method_missing method, *args, &block
        if method.to_s =~ /\=$/ && config.respond_to?(method)
          config.send method, *args, &block
        else
          super
        end
      end
    end

    # Set Telemetry SDK configuration with a block.
    # See {Config} for options.
    #
    # @api public
    def self.configure
      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    end

    # Allows direct access to the config state.  The primary purpose of this method is
    # to access config properties throughout the SDK.
    #
    # @note Unlike configuring with # {#self.configure}, setting config properties here 
    #       may, or may not become immediately active.  Use with care.
    #
    # @api public
    def self.config
      Configurator.config
    end
  end
end
