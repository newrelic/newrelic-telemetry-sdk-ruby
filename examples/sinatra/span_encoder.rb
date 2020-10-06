class SpanEncoder

  def initialize attributes, context
    @attributes = attributes
    @context = context
  end

  def duration
    return (@attributes[:duration] * 1000).to_i if @attributes.has_key?(:duration)
    start = @attributes[:start_time] || Time.now
    finish = @attributes[:end_time] || Time.now
    return ((finish - start) * 1000).to_i
  end

  def encode
    NewRelic::TelemetrySdk::Span.new \
      duration_ms: duration,
      trace_id: @attributes[:trace_id],
      parent_id: @attributes[:parent_id],
      name: @attributes[:name],
      service_name: "Example Service",
      custom_attributes: context
  end
end
