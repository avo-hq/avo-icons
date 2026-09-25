require "concurrent/map"
require "inline_svg"
require "avo/icons/version"
require "avo/icons/configuration"
require "avo/icons/svg_finder"
require "avo/icons/helpers"
require "avo/icons/railtie"

module Avo
  module Icons
    RENDERED_SVGS_LIMIT = 1_000

    class << self
      attr_writer :configuration
      attr_accessor :cached_svgs
      attr_reader :rendered_svgs

      def root
        Pathname.new File.expand_path("..", __dir__)
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end

      def fetch_rendered_svg(cache_key)
        rendered_svgs.fetch_or_store(cache_key) do
          # Host apps can pass per-record args, so drop everything once the cache is full instead of growing forever.
          rendered_svgs.clear if rendered_svgs.size >= RENDERED_SVGS_LIMIT
          yield
        end
      end
    end

    self.cached_svgs = {}
    # Every request thread reads and writes the rendered markup.
    @rendered_svgs = Concurrent::Map.new
  end
end
