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
    Avo::Icons.rendered_svgs.clear
    Avo::Icons.reset_configuration!
    Thread.current[:inline_svg_asset_finder] = nil
    InlineSvg.configure { |config| config.asset_finder = NotFoundAssetFinder }
  end

  teardown do
    Avo::Icons.reset_configuration!
    InlineSvg.reset_configuration!
    Thread.current[:inline_svg_asset_finder] = nil
  end

  # HostView hard-codes the include order, so it cannot catch a flip in the real
  # one. Everything here depends on Avo's helpers shadowing inline_svg's.
  test "Avo's helpers shadow inline_svg's in the booted ActionView::Base" do
    ancestors = ActionView::Base.ancestors

    assert_operator ancestors.index(Avo::Icons::Helpers), :<, ancestors.index(InlineSvg::ActionView::Helpers)
    assert_equal Avo::Icons::Helpers, ActionView::Base.instance_method(:placeholder).owner
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

  test "svg reuses the rendered markup while classes are cached" do
    Dir.mktmpdir do |svg_directory|
      Avo::Icons.configure { |config| config.add_path(svg_directory) }
      File.write(File.join(svg_directory, "cached.svg"), '<svg><path d="M1 1"/></svg>')
      first_output = HostView.new.svg("cached", class: "h-4")

      File.write(File.join(svg_directory, "cached.svg"), '<svg><path d="M2 2"/></svg>')

      assert_includes first_output, 'd="M1 1"'
      assert_equal first_output, HostView.new.svg("cached", class: "h-4")
      assert_includes HostView.new.svg("cached", class: "h-6"), 'd="M2 2"'
    end
  end

  test "svg re-reads the file on every call while code reloads" do
    original_cache_classes = Rails.application.config.cache_classes
    Dir.mktmpdir do |svg_directory|
      Avo::Icons.configure { |config| config.add_path(svg_directory) }
      File.write(File.join(svg_directory, "edited.svg"), '<svg><path d="M1 1"/></svg>')

      Rails.application.config.cache_classes = false
      HostView.new.svg("edited")
      File.write(File.join(svg_directory, "edited.svg"), '<svg><path d="M2 2"/></svg>')

      assert_includes HostView.new.svg("edited"), 'd="M2 2"'
    end
  ensure
    Rails.application.config.cache_classes = original_cache_classes
  end

  test "svg generates fresh aria ids on every call" do
    Dir.mktmpdir do |svg_directory|
      Avo::Icons.configure { |config| config.add_path(svg_directory) }
      File.write(File.join(svg_directory, "titled.svg"), "<svg><title>Search</title></svg>")

      refute_equal HostView.new.svg("titled", aria: true), HostView.new.svg("titled", aria: true)
    end
  end

  test "svg returns a copy the caller can append to" do
    output = HostView.new.svg("tabler/outline/ice-cream-off")
    output << "<span>appended</span>".html_safe

    refute_includes HostView.new.svg("tabler/outline/ice-cream-off"), "appended"
  end

  test "svg empties the markup cache once it reaches its limit" do
    Avo::Icons::RENDERED_SVGS_LIMIT.times { |index| Avo::Icons.rendered_svgs[index] = "<svg></svg>" }

    HostView.new.svg("tabler/outline/ice-cream-off")

    assert_equal 1, Avo::Icons.rendered_svgs.size
  end
end
