# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.
require 'new_relic/telemetry_sdk/logger'

module NewRelic
  module TelemetrySdk
    # This class handles sending data to New Relic automatically at configured
    # intervals.
    #
    # @api public
    class Harvester
      include NewRelic::TelemetrySdk::Logger

      def initialize
        @pipelines = {}
        @shutdown = false
        @running = false
        @lock = Mutex.new
      end

      # Register a pipeline (i.e. a buffer from which data can be harvested
      # via a +flush+ method and a client that can be used to send that data).
      # @param name [String]
      #     A unique name for the type of data associated with this pipeline.
      #     Examples: 'spans', 'external_spans'
      # @param buffer [Buffer]
      #     An instance of NewRelic::TelemetrySdk::Buffer in which data can be
      #     stored for harvest.
      # @param client [Client]
      #     An instance of a NewRelic::TelemetrySdk::Client subclass which will
      #     send harvested data to the correct New Relic backend (e.g. SpanClient
      #     for spans).
      #
      # @api public
      def register name, buffer, client
        logger.info "Registering pipeline #{name}"
        @lock.synchronize do
          @pipelines[name] = {
            buffer: buffer,
            client: client
          }
        end
      rescue => e
        log_error "Encountered error while registering buffer #{name}.", e
      end

      def [] name
        @pipelines[name]
      end

      def interval
        TelemetrySdk.config.harvest_interval
      end

      def running?
        @running
      end

      # Start scheduled harvests via this harvester.
      #
      # @api public
      def start
        logger.info "Harvesting every #{interval} seconds"
        @running = true
        @harvest_thread = Thread.new do
          begin
            while !@shutdown do
              sleep interval
              harvest
            end
            harvest
            @running = false
          rescue => e
            log_error "Encountered error in harvester", e
          end
        end
      end

      # Stop scheduled harvests via this harvester. Any remaining
      # buffered data will be sent before the harvest thread is stopped.
      #
      # @api public
      def stop
        logger.info "Stopping harvester"
        @shutdown = true
        @harvest_thread.join if @running
      rescue => e
        log_error "Encountered error stopping harvester", e
      end

    private

      def harvest
        @lock.synchronize do
          @pipelines.values.each do |pipeline|
            send_data_via pipeline
          end
        end
      end

      def send_data_via pipeline
        batch = pipeline[:buffer].flush
        if !batch.nil? && batch[0].respond_to?(:any?) && batch[0].any?
          pipeline[:client].report_batch batch
        end
      end

    end
  end
end
