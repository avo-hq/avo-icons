module Avo
  module Icons
    class Configuration
      attr_accessor :custom_paths

      def initialize
        @custom_paths = []
      end

      # Add a custom path to search for SVG files
      # @param path [String, Pathname, Proc] A path or proc that returns a path
      # @example
      #   Avo::Icons.configure do |config|
      #     config.add_path("/my/custom/svg/path")
      #     config.add_path(Rails.root.join("vendor", "assets", "svgs"))
      #     config.add_path(->(filename) { File.join("/dynamic/path", filename) })
      #   end
      def add_path(path)
        @custom_paths << path
      end
    end
  end
end
