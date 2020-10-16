# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'new_relic/telemetry_sdk/harvester'

module NewRelic
  module TelemetrySdk
    class HarvesterTest < Minitest::Test

      def log_output
        @log_output.rewind
        @log_output.read
      end

      # default interval is 5 seconds
      def test_default_interval
        harvester = Harvester.new 
        assert_equal 5, harvester.interval
      end

      # stores the registers buffer and client
      def test_register
        harvester = Harvester.new 
        buffer = mock
        client = mock

        harvester.register 'test', buffer, client
        
        expected = {
          buffer: buffer, 
          client: client
        }
        assert_equal expected, harvester['test']
      end

      # process_harestable gets called correct number of times
      def test_harvests_each_harvestable
        harvester = Harvester.new
        buffer = mock
        client = mock

        harvester.register 'test', buffer, client
        harvester.register 'test2', buffer, client

        Harvester.any_instance.expects(:process_harvestable).times(2)
        harvester.send(:harvest)
      end

      # process_harvestable calles correct functions on buffer and client objects
      def test_process_harvestable_with_data
        harvester = Harvester.new
        buffer = mock
        client = mock
        flushed_buffer = [['test_data'], ['common attributes']]

        buffer.expects(:flush).returns(flushed_buffer).once
        client.expects(:report_batch).once

        harvester.send(:process_harvestable, {buffer: buffer, client: client})
      end

      def test_process_harvestable_without_data
        harvester = Harvester.new
        buffer = mock
        client = mock
        flushed_buffer = [[], ['common attributes']]

        buffer.expects(:flush).returns(flushed_buffer).once
        client.expects(:report_batch).never

        harvester.send(:process_harvestable, {buffer: buffer, client: client})
      end

      def test_starts_stops_harvest_thread 
        harvester = Harvester.new 0
        harvester.expects(:harvest).at_least_once

        harvester.start 
        sleep 0.05
        assert_equal true, harvester.running?

        harvester.stop
        assert_equal false, harvester.running?
      end

      def test_harvest_after_loop_shutdown
        harvester = Harvester.new
        harvester.expects(:harvest).once

        harvester.instance_variable_set(:@shutdown, true) 
        harvester.start
        sleep 0.05 # wait for the thread to run through

        harvester.instance_variable_set(:@shutdown, false) # reset it
        harvester.stop
      end

      def test_harvester_interval_runs
        harvester = Harvester.new 42
        harvester.logger = ::Logger.new(@log_output = StringIO.new)

        # calls sleep 3 times with the custom interval of 42
        harvester.expects(:sleep).with(42).times(3)
        # Calls harvest 3 times and raises an error the 3rd time
        harvester.expects(:harvest).returns(nil) \
          .then.returns(nil) \
          .then.raises(RuntimeError.new('pretend error')) \
          .times(3)

        # exception should not bubble up to here
        thread = harvester.start
        thread.join
        # checks logs to ensure the error being raised is logged
        assert_match(/Encountered error in harvester/, log_output)
        assert_match(/pretend error/, log_output)
      end

    end
  end
end