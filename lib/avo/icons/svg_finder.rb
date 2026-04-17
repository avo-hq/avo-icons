module Avo
  module Icons
    class SvgFinder
      def self.find_asset(filename)
        new(filename)
      end

      def initialize(filename)
        @filename = filename
      end

      # Use the default static finder logic. If that doesn't find anything, search according to our pattern:
      def pathname
        Avo::Icons.cached_svgs[@filename] ||= begin
          found_asset = default_strategy

          # Use the found asset
          if found_asset.present?
            found_asset
          else
            paths.find do |path|
              File.exist? path
            end
          end
        end
      end

      def paths
        base_paths = [
          Rails.root.join("app", "assets", "svgs", @filename),
          Rails.root.join(@filename),
          Avo::Icons.root.join("assets", "svgs", @filename),
          Avo::Icons.root.join("assets", "svgs", "tabler", "outline", @filename),
          Avo::Icons.root.join("assets", "svgs", "tabler", "filled", @filename),
          Avo::Icons.root.join("assets", "svgs", "heroicons", "outline", @filename),
          Avo::Icons.root.join("assets", "svgs", "heroicons", "solid", @filename),
          Avo::Icons.root.join("assets", "svgs", "heroicons", "mini", @filename),
          Avo::Icons.root.join("assets", "svgs", "heroicons", "micro", @filename),
          # Add all paths from Rails including engines
          *Rails.application.config.assets&.paths&.map { |path| File.join(path, @filename) }
        ]

        # Add custom paths from configuration
        custom_paths = Avo::Icons.configuration.custom_paths.map do |custom_path|
          if custom_path.is_a?(Proc)
            custom_path.call(@filename)
          else
            File.join(custom_path.to_s, @filename)
          end
        end

        (base_paths + custom_paths).map(&:to_s).uniq
      end

      def default_strategy
        # If the app uses Propshaft, grab it from there
        if defined?(Propshaft)
          asset_path = ::Rails.application.assets.load_path.find(@filename)
          asset_path&.path
        elsif ::Rails.application.config.assets.compile
          # Grab the asset from the compiled asset manifest
          asset = ::Rails.application.assets[@filename]
          Pathname.new(asset.filename) if asset.present?
        else
          # Grab the asset from the manifest
          manifest = ::Rails.application.assets_manifest
          asset_path = manifest.assets[@filename]
          unless asset_path.nil?
            ::Rails.root.join(manifest.directory, asset_path)
          end
        end
      end
    end
  end
end

