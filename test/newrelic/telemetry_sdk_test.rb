require "test_helper"

class NewRelic::TelemetrySdkTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::NewRelic::TelemetrySdk::VERSION
  end

  def test_it_returns_gem_version
    gem_version = ::NewRelic::TelemetrySdk.gem_version

    assert gem_version.is_a? Gem::Version
    assert_equal ::NewRelic::TelemetrySdk::VERSION, gem_version.version
  end
end
