require 'net/http'
require 'bundler'
Bundler.require

unless ENV["API_KEY"]
  raise "No License key supplied.  Export API_KEY environment variable!" 
end

def random_id length=16
  length.times.map{rand(16).to_s(16)}.join
end

def span_client
  return @span_client if @span_client
  @span_client = NewRelic::TelemetrySdk::SpanClient.new
end

def record_external_request
  start_time = Time.now
  response = yield
  finish_time = Time.now
  duration = finish_time - start_time

  raise response.inspect
  custom_attributes = {
    "name": response.path,
    "http.method": "GET",
    "http.status": response.status,
    "size": response.body.bytesize,
  }

  span = NewRelic::TelemetrySdk::Span.new(
    id: random_id(8),
    trace_id: random_id(16),
    start_time_ms: (start_time * 1000).to_i,
    duration_ms: (duration * 1000).to_i,
    name: "get_#{response.path}",
    custom_attributes: custom_attributes
  )
  span_client.report span

  response
end

def get_page url
  uri = URI::parse(url)
  response = record_external_request do
    Net::HTTP.get_response(uri)
  end
  puts "Fetched: #{uri}"
  puts "Status: #{response.status}"
  puts "Size: #{response.body.bytesize}"
end

# telemetry.ConfigCommonAttributes(map[string]interface{}{
#   "app.name":  "myServer",
#   "host.name": "dev.server.com",
#   "env":       "staging",
# }),

get_page "https://google.com"