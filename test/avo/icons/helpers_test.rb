require "test_helper"

class Avo::Icons::HelpersTest < ActiveSupport::TestCase
  # Mirrors the Railtie's include order: inline_svg's helpers land in
  # ActionView::Base first, then Avo::Icons::Helpers shadows them.
  class HostView
    include InlineSvg::ActionView::Helpers
    include Avo::Icons::Helpers
  end

  # Stands in for a host app's configured asset finder. The dummy app has no
  # asset pipeline, so inline_svg's default StaticAssetFinder raises before
  # the missing-file placeholder is ever reached.
  class NotFoundAssetFinder
    Asset = Struct.new(:pathname)

    def self.find_asset(_filename)
      Asset.new(nil)
    end
  end

  setup do
    Avo::Icons.cached_svgs = {}
    Avo::Icons.reset_configuration!
    Thread.current[:inline_svg_asset_finder] = nil
    InlineSvg.configure { |config| config.asset_finder = NotFoundAssetFinder }
  end

  teardown do
    Avo::Icons.reset_configuration!
    InlineSvg.reset_configuration!
    Thread.current[:inline_svg_asset_finder] = nil
  end

  test "host-app inline_svg renders inline_svg's silent placeholder for missing files" do
    output = HostView.new.inline_svg("does-not-exist.svg")

    assert_equal "<svg><!-- SVG file not found: 'does-not-exist.svg' --></svg>", output
    refute_includes output, "avo-missing-svg"
    refute_includes output, "icon-tabler-ice-cream-off"
  end

  test "host-app inline_svg_tag renders inline_svg's silent placeholder for missing files" do
    output = HostView.new.inline_svg_tag("does-not-exist.svg")

    assert_equal "<svg><!-- SVG file not found: 'does-not-exist.svg' --></svg>", output
    refute_includes output, "avo-missing-svg"
    refute_includes output, "icon-tabler-ice-cream-off"
  end

  test "host-app missing file placeholder honors svg_not_found_css_class" do
    InlineSvg.configure { |config| config.svg_not_found_css_class = "missing" }

    output = HostView.new.inline_svg("does-not-exist.svg")

    assert_includes output, "class='missing'"
    refute_includes output, "avo-missing-svg"
  end

  test "svg renders the loud missing icon placeholder for missing files" do
    output = HostView.new.svg("does-not-exist")

    assert_includes output, "avo-missing-svg"
    assert_includes output, "icon-tabler-ice-cream-off"
    assert_includes output, "title='SVG file not found: does-not-exist.svg'"
  end

  test "svg escapes the filename in the placeholder title and comment" do
    output = HostView.new.svg("x' onmouseover='alert(1)")

    assert_includes output, "title='SVG file not found: x&#39; onmouseover=&#39;alert(1).svg'"
    assert_includes output, "<!-- SVG file not found: 'x&#39; onmouseover=&#39;alert(1).svg' -->"
    refute_includes output, "onmouseover='alert(1)"
  end

  test "placeholder without inline_svg in the ancestry falls back to escaped silent markup" do
    helper = Class.new do
      include Avo::Icons::Helpers
    end.new

    output = helper.send(:placeholder, "x' onmouseover='alert(1)")

    assert_equal "<svg><!-- SVG file not found: 'x&#39; onmouseover=&#39;alert(1)' --></svg>", output
    refute_includes output, "onmouseover='alert(1)"
  end

  test "svg clears the asset finder thread-local when rendering raises" do
    view = HostView.new
    # #svg calls inline_svg inside with_asset_finder, so raising here surfaces
    # the exception while the Avo finder marker is set.
    def view.inline_svg(*)
      raise "boom"
    end

    error = assert_raises(RuntimeError) { view.svg("anything") }

    assert_equal "boom", error.message
    assert_nil Thread.current[:inline_svg_asset_finder]
  end

  test "svg restores a pre-existing asset finder thread-local instead of clobbering it" do
    sentinel = Object.new
    Thread.current[:inline_svg_asset_finder] = sentinel

    HostView.new.svg("tabler/outline/ice-cream-off")

    assert_same sentinel, Thread.current[:inline_svg_asset_finder]
  end

  test "svg renders a bundled icon without the missing icon wrapper" do
    output = HostView.new.svg("tabler/outline/ice-cream-off")

    assert_includes output, "<svg"
    assert_includes output, "icon-tabler-ice-cream-off"
    refute_includes output, "avo-missing-svg"
    refute_includes output, "<div"
  end
end
