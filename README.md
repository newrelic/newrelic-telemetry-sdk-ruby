[![Archived header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Archived.png)](https://opensource.newrelic.com/oss-category/#archived)

Archival Notice
❗Notice: This project has been archived as is and is no longer actively maintained.

Rather than developing a Ruby specific OpenTelemetry exporter New Relic has adopted a language agnostic approach that facilitates data collection from all OpenTelemetry data sources.

The current recommended approaches for sending OpenTelemetry data to the New Relic platform are as follows:

* Configure your OpenTelemetry data source to send data to the [OpenTelemetry Collector](https://docs.newrelic.com/docs/integrations/open-source-telemetry-integrations/opentelemetry/introduction-opentelemetry-new-relic/#collector) using the OpenTelemetry Protocol (OTLP) and configure the collector to forward the data using the [New Relic collector exporter](https://github.com/newrelic-forks/opentelemetry-collector-contrib/tree/newrelic-main/exporter/newrelicexporter).
* Configure your OpenTelemetry data source to send data to the native OpenTelemetry Protocol (OTLP) data ingestion endpoint. [OTLP](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/otlp.md) is an open source gRPC based protocol for sending telemetry data. The protocol is vendor agnostic and open source.

For more details please see:
* [OpenTelemetry quick start](https://docs.newrelic.com/docs/integrations/open-source-telemetry-integrations/opentelemetry/opentelemetry-quick-start/)
* [Introduction to OpenTelemetry with New Relic](https://docs.newrelic.com/docs/integrations/open-source-telemetry-integrations/opentelemetry/introduction-opentelemetry-new-relic/)
* [Native OpenTelemetry Protocol (OTLP) support](https://docs.newrelic.com/whats-new/2021/04/native-support-opentelemetry/)

# New Relic Ruby Telemetry SDK
The New Relic Ruby Telemetry SDK is an easy way to send data to New Relic. The SDK currently supports sending span/trace data via New Relic's [Trace API](https://docs.newrelic.com/docs/understand-dependencies/distributed-tracing/trace-api/introduction-trace-api).

Why is this cool?

Send data to New Relic! No agent required.

Our [Telemetry SDK](https://docs.newrelic.com/docs/data-ingest-apis/get-data-new-relic/new-relic-sdks/telemetry-sdks-send-custom-telemetry-data-new-relic) makes it easier for you to send your telemetry data to New Relic. We've covered all of the basics for you so you can focus on writing feature code directly related to your business need or interest.

## Installation

### With Bundler

For using with Bundler, add the New Relic Telemetry SDK gem to your project's Gemfile.

```ruby
gem 'newrelic-telemetry_sdk'
```

and run `bundle install` to activate the new gem.

### Without Bundler

If you are not using Bundler, install the gem with:

```bash
gem install newrelic-telemetry_sdk
```

and then require the New Relic Ruby Telemetry SDK in your Ruby start-up sequence:

```ruby
require 'newrelic-telemetry_sdk'
```

## Getting Started

### Sending your first span

The example code assumes you've set the following environment variables:

* NEW_RELIC_INSERT_KEY

```
NewRelic::TelemetrySdk.configure do |config|
   config.api_insert_key = ENV["NEW_RELIC_INSERT_KEY"]
end

span = NewRelic::TelemetrySdk::Span.new
sleep 1
span.finish
client = NewRelic::TelemetrySdk::TraceClient.new
client.report span
```

For more detailed examples please see [our examples directory](./examples).

## Testing

Running the test suite is simple.  Just invoke:

    bundle
    bundle exec rake

## Support

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub. You can find this project's topic/threads here:

https://discuss.newrelic.com/t/new-relic-telemetry-sdk-for-ruby/114266

## Contributing
We encourage your contributions to improve newrelic-telemetry-sdk-ruby! Keep in mind when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.
If you have any questions, or to execute our corporate CLA, required if your contribution is on behalf of a company,  please drop us an email at opensource@newrelic.com.

## License
newrelic-telemetry-sdk-ruby is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.

## Find and use data

Tips on how to find and query your data in New Relic:

* [Find metric data](https://docs.newrelic.com/docs/data-ingest-apis/get-data-new-relic/metric-api/introduction-metric-api#find-data)
* [Find event data](https://docs.newrelic.com/docs/insights/insights-data-sources/custom-data/introduction-event-api#find-data)
* [Find trace/span data](https://docs.newrelic.com/docs/understand-dependencies/distributed-tracing/trace-api/introduction-trace-api#view-data>)

For general querying information, see:

* [Query New Relic data](https://docs.newrelic.com/docs/using-new-relic/data/understand-data/query-new-relic-data)
* [Intro to NRQL](https://docs.newrelic.com/docs/query-data/nrql-new-relic-query-language/getting-started/introduction-nrql)

## Limitations

The New Relic Telemetry APIs are rate limited. Please reference the documentation for [New Relic Metrics API](https://docs.newrelic.com/docs/introduction-new-relic-metric-api) and [New Relic Trace API requirements and limits](https://docs.newrelic.com/docs/apm/distributed-tracing/trace-api/trace-api-general-requirements-limits) on the specifics of the rate limits.
