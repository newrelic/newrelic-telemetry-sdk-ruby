require "new_relic/telemetry_sdk"

class Exporter
  def initialize api_key
    ENV["API_KEY"] = api_key # not ideal, but it should work...
    @client = NewRelic::TelemetrySdk::SpanClient.new
  end

  def << span_or_trace
    # gotta record 'em somehow!    
    Array(span_or_trace).each do |span|
      pp span
    end
  end
end