require "inline_svg"
require "avo/icons/version"
require "avo/icons/configuration"
require "avo/icons/svg_finder"
require "avo/icons/helpers"
require "avo/icons/railtie"

module Avo
  module Icons
    class << self
      attr_writer :configuration
      attr_accessor :cached_svgs

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
    end

    # Initialize cache
    self.cached_svgs = {}
  end
end
