require 'net/http'
require 'bundler'
Bundler.require

require "new_relic/telemetry_sdk"

unless ENV["API_KEY"]
  raise "No License key supplied.  Export API_KEY environment variable!" 
end

def setup_buffer_harvesting common_attributes = {test_attribute: 'example'}
  @harvester = NewRelic::TelemetrySdk::Harvester.new 
  @span_client = NewRelic::TelemetrySdk::SpanClient.new
  @buffer = NewRelic::TelemetrySdk::Buffer.new common_attributes
  @harvester.register 'external_spans', @buffer, @span_client
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
    "name": "Net::HTTP#get",
    "http.method": "GET",
    "http.status": response.code,
    "size": response.body.bytesize,
  }

  span = NewRelic::TelemetrySdk::Span.new(
    id: random_id(8),
    trace_id: random_id(16),
    start_time_ms: (start_time.to_i * 1000),
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
setup_buffer_harvesting

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
