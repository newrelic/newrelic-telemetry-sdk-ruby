require "sinatra/base"
require_relative "span_encoder"
require_relative "trace_encoder"
require_relative "exporter"

unless ENV["NEWRELIC_TELEMETRY_API_KEY"]
  raise "No License key supplied.  Export NEWRELIC_TELEMETRY_API_KEY environment variable!" 
end

class Demo < Sinatra::Base

  # imagines a callstack as a trace
  def callstack_as_a_trace callstack
    callstack.map{|cs| cs.split("/")[-1]}.map do |line|
      if match = line.match(/(\w+\.rb):(\d+):in\s`(\w+)'/)
        {name: "#{match[1]}/#{match[3]}", duration: match[2]}
      end
    end.compact
  end

  def exporter
    @exporter ||= Exporter.new(ENV["NEWRELIC_TELEMETRY_API_KEY"])
  end

  get '/' do
    trace = TraceEncoder.new \
      callstack_as_a_trace(caller), 
      { app: "Sinatra::#{self.class}", method: "get", path: "/", host: `hostname` }

    exporter << trace.encode
    "The best is yet to come and won’t that be fine. – Frank Sinatra"
  end

  # $0 is the executed file
  # __FILE__ is the current file
  run! if __FILE__ == $0
end
