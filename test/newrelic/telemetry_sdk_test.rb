require "test_helper"

class Newrelic::TelemetrySdkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Newrelic::TelemetrySdk::VERSION
  end
end
