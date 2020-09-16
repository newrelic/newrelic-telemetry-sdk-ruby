require "test_helper"

class NewRelic::TelemetrySdkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::NewRelic::TelemetrySdk::VERSION
  end
end
