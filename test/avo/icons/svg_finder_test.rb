require "test_helper"

class Avo::Icons::SvgFinderTest < ActiveSupport::TestCase
  setup do
    Avo::Icons.cached_svgs = {}
    Avo::Icons.reset_configuration!
  end

  teardown { Avo::Icons.reset_configuration! }

  test "resolves a real bundled icon by its full path" do
    pathname = Avo::Icons::SvgFinder.find_asset("tabler/outline/search.svg").pathname

    assert pathname, "expected the finder to locate a bundled icon"
    assert File.exist?(pathname)
    assert_equal "search.svg", File.basename(pathname)
  end

  test "resolves a bare tabler icon name via the outline/filled fallback paths" do
    pathname = Avo::Icons::SvgFinder.find_asset("user.svg").pathname

    assert pathname
    assert File.exist?(pathname)
  end

  test "returns nil for an icon that does not exist" do
    assert_nil Avo::Icons::SvgFinder.find_asset("does/not/exist.svg").pathname
  end

  test "search paths include the bundled tabler and heroicons locations" do
    paths = Avo::Icons::SvgFinder.find_asset("search.svg").paths

    assert(paths.any? { |p| p.include?(File.join("svgs", "tabler", "outline")) })
    assert(paths.any? { |p| p.include?(File.join("svgs", "heroicons", "outline")) })
  end

  test "configured custom paths are searched" do
    Avo::Icons.configure { |c| c.add_path("/my/custom/svgs") }
    paths = Avo::Icons::SvgFinder.find_asset("thing.svg").paths

    assert_includes paths, "/my/custom/svgs/thing.svg"
  end

  test "configured proc paths receive the filename" do
    Avo::Icons.configure { |c| c.add_path(->(file) { "/dynamic/#{file}" }) }
    paths = Avo::Icons::SvgFinder.find_asset("thing.svg").paths

    assert_includes paths, "/dynamic/thing.svg"
  end

  test "results are memoized in the shared cache" do
    Avo::Icons::SvgFinder.find_asset("tabler/outline/search.svg").pathname

    assert Avo::Icons.cached_svgs.key?("tabler/outline/search.svg")
  end
end
