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

        # inline_svg reads the file and runs a Nokogiri transform on every call, so reuse the markup
        # once code stops reloading. `aria: true` makes inline_svg generate random ids, which must differ per render.
        return render_svg(file_name, **args) if !Rails.application.config.cache_classes || args[:aria]

        # A copy, so a caller appending to the result cannot change the cached markup.
        Avo::Icons.fetch_rendered_svg([ file_name, args ]) { render_svg(file_name, **args) }.dup
      end

      private

      def render_svg(file_name, **args)
        with_asset_finder(Avo::Icons::SvgFinder) do
          inline_svg file_name, **args
        end
      end

      # Override inline_svg's placeholder, but only for lookups made through
      # our #svg helper (detected via the asset finder thread-local). Host app
      # calls to inline_svg/inline_svg_tag keep inline_svg's own behavior.
      # https://github.com/jamesmartin/inline_svg/blob/main/lib/inline_svg/action_view/helpers.rb#L61
      def placeholder(filename)
        return avo_missing_svg_placeholder(filename) if Thread.current[:inline_svg_asset_finder] == Avo::Icons::SvgFinder
        return super if defined?(super)

        # Minimal silent placeholder for direct calls outside a full ActionView
        # helper chain. Mirrors inline_svg's default shape only — it does not
        # consult svg_not_found_css_class or add the extension hint.
        escaped_filename = ERB::Util.html_escape_once(filename.to_s)
        "<svg><!-- SVG file not found: '#{escaped_filename}' --></svg>".html_safe
      end

      # The loud debug glyph rendered when an Avo icon lookup misses.
      def avo_missing_svg_placeholder(filename)
        css_class = "avo-missing-svg"
        escaped_filename = ERB::Util.html_escape_once(filename.to_s)
        missing_icon = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon icon-tabler icons-tabler-outline icon-tabler-ice-cream-off"><path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M12 21.5v-4.5" /><path d="M8 8v9h8v-1m0 -4v-5a4 4 0 0 0 -7.277 -2.294" /><path d="M8 10.5l1.74 -.76m2.79 -1.222l3.47 -1.518" /><path d="M8 14.5l4.488 -1.964" /><path d="M3 3l18 18" /></svg>'
        "<div data-tippy='tooltip' class='#{css_class}' style='width: 2rem; height: 2rem; color: #ef4444;' title='SVG file not found: #{escaped_filename}'><!-- SVG file not found: '#{escaped_filename}' -->#{missing_icon}</div>".html_safe
      end

      # Adapted from the original library, with an ensure so the Avo finder
      # marker (which #placeholder keys off) cannot outlive the call — even
      # when the block raises — and any pre-existing finder is restored
      # instead of clobbered.
      # https://github.com/jamesmartin/inline_svg/blob/main/lib/inline_svg/action_view/helpers.rb#L76
      def with_asset_finder(asset_finder)
        previous_asset_finder = Thread.current[:inline_svg_asset_finder]
        Thread.current[:inline_svg_asset_finder] = asset_finder

        yield
      ensure
        Thread.current[:inline_svg_asset_finder] = previous_asset_finder
      end
    end
  end
end
