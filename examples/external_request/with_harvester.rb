require 'net/http'
require 'bundler'
Bundler.require

require "new_relic/telemetry_sdk"

unless ENV["API_KEY"]
  raise "No API Key supplied.  Export API_KEY environment variable!" 
end

def configure_sdk
  NewRelic::TelemetrySdk.configure do |config|
    config.api_insert_key = ENV["API_KEY"]
  end
end

def setup_buffer_harvesting common_attributes = {host: 'fake_host'}
  configure_sdk
  @harvester = NewRelic::TelemetrySdk::Harvester.new 
  @span_client = NewRelic::TelemetrySdk::SpanClient.new
  # Creates a buffer with common attributes that will be added to all spans in the buffer
  @buffer = NewRelic::TelemetrySdk::Buffer.new common_attributes
  # Register the buffer with a name and the associated client
  @harvester.register 'external_spans', @buffer, @span_client
  # Begins the harvester running in the background
  @harvester.start
end

def stop_harvester
  @harvester.stop
end

def random_id length=16
  length.times.map{rand(16).to_s(16)}.join
end

def record_external_request
  start_time = Time.now
  response = yield
  finish_time = Time.now
  duration = finish_time - start_time

  custom_attributes = {
    "http.status": response.code,
    "size": response.body.bytesize,
  }

  span = NewRelic::TelemetrySdk::Span.new(
    id: random_id(16),
    trace_id: random_id(32),
    start_time: start_time,
    duration_ms: (duration * 1000).to_i,
    name: "Net::HTTP#get",
    custom_attributes: custom_attributes
  )
  @buffer.record span

  response
end

def get_page url
  uri = URI::parse(url)
  response = record_external_request do
    conn = Net::HTTP.new uri.host, uri.port
    conn.use_ssl = true
    conn.request_get("/")
  end
  puts "Fetched: #{uri}"
  puts "Status: #{response.code}"
  puts "Size: #{response.body.bytesize}"
end

# Creates the buffer, client, and harvester
common_attributes = {"name": "Net::HTTP#get", "http.method": "GET"}
setup_buffer_harvesting common_attributes

# Buffer holds multiple spans, spans are added to the buffer in the record_external_request_method
get_page "https://google.com"
get_page "https://google.com"
get_page "https://google.com"

# allow harvester time to send data, default interval is 5 seconds
sleep 6 
# buffer is now empty

get_page "https://google.com"
get_page "https://google.com"
get_page "https://google.com"

# harvester will flush remaining data in buffer when stopped
stop_harvester
