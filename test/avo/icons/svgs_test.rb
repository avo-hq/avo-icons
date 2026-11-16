require "test_helper"

class Avo::Icons::SvgsTest < ActiveSupport::TestCase
  # inline_svg pastes these files into admin pages as they are, and a merge to main releases them on its own.
  SCRIPTABLE = /<script|<foreignObject|<iframe|<embed|<object|\son[a-z]+\s*=|javascript:|href\s*=\s*["'](?:https?|data):/i

  test "no shipped icon can run script or load a remote resource" do
    offenders = Dir[Avo::Icons.root.join("assets/svgs/**/*.svg").to_s].select { |path| File.read(path).match?(SCRIPTABLE) }

    assert_empty offenders
  end
end
