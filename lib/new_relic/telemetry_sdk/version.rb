module NewRelic
  module TelemetrySdk
    VERSION = "0.1.0"

    extend self

    def gem_version
      Gem::Version.create VERSION
    end
  end
end
