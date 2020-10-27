# This example is one of the simplest examples demonstrating sending one span 
# at at time to the Trace API endpoint.  It will time how long it takes to retrive
# an external URL's content and construct a span and send it to New Relic's server.
# 
# Usage: `API_KEY=<YOUR_API_KEY> bundle exec ruby simple.rb`
require 'net/http'
require 'bundler'
Bundler.require

require "new_relic/telemetry_sdk"

# Fail fast if an API_KEY wasn't exported to the environment.
unless ENV["API_KEY"]
  raise "No API Key supplied.  Export API_KEY environment variable!" 
end

# Just a random ID generator -- A string of 16 (by default) hexadecimal digits.
def random_id length=16
  length.times.map{rand(16).to_s(16)}.join
end

def configure_sdk
  NewRelic::TelemetrySdk.configure do |config|
    config.api_insert_key = ENV["API_KEY"]
  end
end

# Instantiates and memoizes the SDK client for sending Spans
def trace_client
  return @trace_client if @trace_client
  configure_sdk
  @trace_client = NewRelic::TelemetrySdk::SpanClient.new
end

# Wraps the given block by recording time to retrieve URL's resource, then
# constructs the span object and sends it to the server.
# The response from the given block is returned as the method's result
def record_external_request
  # Capture time elapsed to make the external request (given block)
  start_time = Time.now
  response = yield
  finish_time = Time.now
  duration = finish_time - start_time

  # Set some custom attributes for the Span (some static, some dynamic)
  custom_attributes = {
    "name": "Net::HTTP#get",
    "http.method": "GET",
    "http.status": response.code,
    "size": response.body.bytesize,
  }

  # Construct the span and send it.
  span = NewRelic::TelemetrySdk::Span.new(
    id: random_id(16),
    trace_id: random_id(32),
    start_time: start_time,
    duration_ms: (duration * 1000).to_i,
    name: "Net::HTTP#get",
    custom_attributes: custom_attributes
  )
  trace_client.report span

  # return the results from the given block/proc
  response
end

# Retrieve the resource from given URL, recording a span
# for the operation.
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

get_page "https://google.com"