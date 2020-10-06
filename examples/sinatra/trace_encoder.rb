class TraceEncoder
  def initialize traces, context
    @traces = traces
    @context = context
  end

  def encode
    @traces.map do |span_attributes|
      SpanEncoder.new(span_attributes, @context)
    end
  end
end