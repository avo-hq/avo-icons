module Avo
  module Icons
    module Helpers
      # Use inline_svg gem but with our own finder implementation.
      # @param file_name [String] The name of the SVG file (with or without .svg extension)
      # @param args [Hash] Additional arguments to pass to inline_svg
      # @return [String] The inline SVG HTML
      # @example
      #   svg("heroicons/outline/user", class: "w-6 h-6")
      #   svg("my-icon", class: "w-4 h-4", aria: { hidden: true })
      def svg(file_name, **args)
        return if file_name.blank?

        file_name = "#{file_name}.svg" unless file_name.end_with? ".svg"

        with_asset_finder(Avo::Icons::SvgFinder) do
          inline_svg file_name, **args
        end
      end

      private

      # Override inline_svg's placeholder to use our own css class.
      # https://github.com/jamesmartin/inline_svg/blob/main/lib/inline_svg/action_view/helpers.rb#L61
      def placeholder(filename)
        css_class = "avo-missing-svg"
        "<div class='#{css_class}' style='width: 1rem; height: 1rem; border: 1px solid #ef4444; border-radius: 0.25rem;' title='SVG file not found: #{filename}'><!-- SVG file not found: '#{ERB::Util.html_escape_once(filename)}' --></div>".html_safe
      end

      # Taken from the original library
      # https://github.com/jamesmartin/inline_svg/blob/main/lib/inline_svg/action_view/helpers.rb#L76
      def with_asset_finder(asset_finder)
        Thread.current[:inline_svg_asset_finder] = asset_finder
        output = yield
        Thread.current[:inline_svg_asset_finder] = nil

        output
      end
    end
  end
end

