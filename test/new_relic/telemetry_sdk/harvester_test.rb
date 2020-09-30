# encoding: utf-8
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/LICENSE for complete details.


require File.expand_path(File.join(File.dirname(__FILE__),'../..','test_helper'))

require 'new_relic/telemetry_sdk/harvester'


module NewRelic
  module TelemetrySdk
    class HarvesterTest < Minitest::Test

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
        assert_equal expected, harvester.lookup('test')
      end

      # process_harestable gets called correct number of times
      def test_harvests_each_harvestable
        harvester = Harvester.new
        buffer = mock
        client = mock

        harvester.register 'test', buffer, client
        harvester.register 'test2', buffer, client

        Harvester.any_instance.expects(:process_harvestable).times(2)
        harvester.harvest
      end

      # process_harvestable calles correct functions on buffer and client objects
      def test_process_harvestable
        harvester = Harvester.new
        buffer = mock
        client = mock

        buffer.expects(:flush).once
        client.expects(:report_batch).once

        harvester.process_harvestable ({buffer: buffer, client: client})
      end

      def test_stops_harvest_thread 
        harvester = Harvester.new 0
        harvester.expects(:harvest).at_least_once

        harvester.start 
        sleep 0.05
        assert_equal true, harvester.is_running?

        harvester.stop
        assert_equal false, harvester.is_running?
      end

    end
  end
end