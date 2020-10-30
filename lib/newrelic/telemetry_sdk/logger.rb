# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    # The Logger Singleton object manages the logger for the SDK and is fully configurable by the user.  
    # Any Ruby class that responds to the common methods of the Ruby standard {::Logger} class can
    # be configured for the SDk.
    # 
    # The logger may be configured like this:
    # @example with configure block
    #   require 'logger'
    #
    #   logger = ::Logger.new(STDOUT)
    #   logger.level = Logger::WARN
    #
    #   NewRelic::TelemetrySdk.configure do |config|
    #     config.logger = logger
    #   end
    #
    # @example without configure block
    #   require 'logger'
    #   
    #   NewRelic::TelemetrySdk.logger = ::Logger.new("/dev/null")
    #
    # @api public
    module Logger
      LOG_LEVELS = %w{debug info warn error fatal}
      private_constant :LOG_LEVELS
      
      LOG_LEVELS.each do |level|
        define_method "log_#{level}_once" do |key, *msgs|
          log_once level, key, *msgs
        end
      end

      def self.logger= logger
        @logger = logger
      end
    
      def self.logger
        @logger ||= ::Logger.new(STDOUT)
      end
    
      def log_once(level, key, *msgs)
        logger_mutex.synchronize do
          return if already_logged.include?(key)
          already_logged[key] = true
        end

        logger.send(level, *msgs)
      end

      def clear_already_logged
        logger_mutex.synchronize do
          @already_logged = {}
        end
      end

      def log_error(message, exception = nil)
        logger.error message
        logger.error exception if exception
      end

      def logger
        Logger.logger
      end
      
      def logger= logger
        Logger.logger = logger
      end

      private

      def logger_mutex
        @logger_mutex ||= Mutex.new
      end

      def already_logged
        @already_logged ||= {}
      end
    end

    def self.logger
      Logger.logger
    end
  end
end
