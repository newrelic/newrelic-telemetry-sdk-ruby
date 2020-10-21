module NewRelic
  module TelemetrySdk
    module Logger
      LOG_LEVELS = %w{debug info warn error fatal}

      LOG_LEVELS.each do |level|
        define_method "log_#{level}_once" do |key, *msgs|
          log_once level, key, *msgs
        end
      end

      def logger
        @logger ||= ::Logger.new(STDOUT)
      end

      def logger= logger
        @logger = logger
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

      def log_error(exception, message)
        logger.error message
        logger.error exception
      end

    end
  end
end
