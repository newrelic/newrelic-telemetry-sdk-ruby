

module NewRelic
  module TelemetrySdk
    class Harvester


      def initialize 

      end

      def start
        @harvest_thread = Thread.new do
          while !@shutdown do
            sleep @interval
            harvest
          end
        end
      end

      def stop
        @shutdown = true
        @harvest_thread.join
      end

      def harvest 

      end

    end
  end
end
