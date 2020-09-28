lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "new_relic/telemetry_sdk/version"

Gem::Specification.new do |spec|
  spec.name          = "newrelic-telemetry_sdk"
  spec.version       = NewRelic::TelemetrySdk::VERSION
  spec.authors       = ["Rachel Klein", "Tanna McClure", "Michael Lang"]
  spec.email         = ["support@newrelic.com"]

  spec.summary       = %q{New Relic Telemetry SDK}
  spec.description   = <<-EOS
Send your telemetry data to New Relic, no agent required.
EOS
  spec.homepage      = "https://newrelic.com/ruby"
  spec.licenses      = ['Apache-2.0']

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/newrelic/newrelic-telemetry-sdk-ruby/"
  spec.metadata["changelog_uri"] = "https://github.com/newrelic/newrelic-telemetry-sdk-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry-nav", "~> 0.3.0"
  spec.add_development_dependency "timecop", "~> 0.9"
end
