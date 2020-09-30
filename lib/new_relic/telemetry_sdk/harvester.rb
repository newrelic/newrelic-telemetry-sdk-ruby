# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

module NewRelic
  module TelemetrySdk
    class Harvester

      attr_reader :interval

      def initialize interval = 5
        @interval = interval
        @harvestables = {}
        @shutdown = false
        @running = false
        @lock = Mutex.new
      end

      def register name, buffer, client
        @lock.synchronize do 
          @harvestables[name] = {
            buffer: buffer,
            client: client
          }
        end
      end

      def lookup name 
        @harvestables[name]
      end

      def is_running?
        @running
      end
      
      def start
        @running = true
        @harvest_thread = Thread.new do
          while !@shutdown do
            sleep @interval
            harvest
          end
          @running = false
        end
      end

      def stop
        @shutdown = true
        @harvest_thread.join
      end

      def harvest
        @lock.synchronize do
          @harvestables.each do |harvestable|
            process_harvestable harvestable
          end
        end
      end

      def process_harvestable harvestable
        harvestable[:client].report_batch harvestable[:buffer].flush
      end

    end
  end
end
