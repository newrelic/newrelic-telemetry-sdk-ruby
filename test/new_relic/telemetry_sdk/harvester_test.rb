# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.

require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'new_relic/telemetry_sdk/harvester'

module NewRelic
  module TelemetrySdk
    class HarvesterTest < Minitest::Test

      def setup
        NewRelic::TelemetrySdk.configure do |config|
          config.logger = ::Logger.new(@log_output = StringIO.new)
        end
      end

      def teardown
        Configurator.reset
      end

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
        assert_match "Registering harvestable test", log_output
      end

      # process_harvestable gets called correct number of times
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
        NewRelic::TelemetrySdk.configure{|config| config.harvest_interval = 0}
        harvester = Harvester.new

        harvester.expects(:harvest).at_least_once

        harvester.start
        sleep 0.05
        assert_equal true, harvester.running?
        assert_match "Harvesting every 0 seconds", log_output

        harvester.stop
        assert_equal false, harvester.running?
        assert_match "Stopping harvester", log_output
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
        NewRelic::TelemetrySdk.configure{|config| config.harvest_interval = 42}
        harvester = Harvester.new

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

      def test_register_logs_error
        harvester = Harvester.new
        harvester.instance_variable_get(:@lock).stubs(:synchronize).raises(StandardError.new('pretend_error'))
        harvester.register("test buffer", stub, stub)
        assert_match(/Encountered error while registering buffer test buffer./, log_output)
        assert_match(/pretend_error/, log_output)
      end

      def test_stop_logs_error
        harvester = Harvester.new
        harvester.start
        harvester.instance_variable_get(:@harvest_thread).stubs(:join).raises(StandardError.new('pretend_error'))

        harvester.stop

        assert_match(/Encountered error stopping harvester/, log_output)
        assert_match(/pretend_error/, log_output)
      end
    end
  end
end
