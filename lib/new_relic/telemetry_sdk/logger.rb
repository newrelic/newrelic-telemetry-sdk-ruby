# encoding: utf-8
# frozen_string_literal: true
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    def self.logger
      Logger.logger
    end
        
    module Logger
      LOG_LEVELS = %w{debug info warn error fatal}

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
    
      def logger
        Logger.logger
      end
      
      def logger= logger
        Logger.logger = logger
      end

      def logger_mutex
        @logger_mutex ||= Mutex.new
      end

      def already_logged
        @already_logged ||= {}
      end

      def log_once(level, key, *msgs)
        logger_mutex.synchronize do
          return if already_logged.include?(key)
          already_logged[key] = true
        end

        logger.send(level, *msgs)
      end

      def clear_already_logged
        already_logged_lock.synchronize do
          @already_logged = {}
        end
      end
    end
  end
end
