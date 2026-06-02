require "test_helper"

class Avo::Icons::HelpersTest < ActiveSupport::TestCase
  test "placeholder escapes filename in title and comment" do
    helper = Class.new do
      include Avo::Icons::Helpers
    end.new

    filename = "x' onmouseover='alert(1)"
    output = helper.send(:placeholder, filename)

    assert_includes output, "title='SVG file not found: x&#39; onmouseover=&#39;alert(1)'"
    assert_includes output, "<!-- SVG file not found: 'x&#39; onmouseover=&#39;alert(1)' -->"
    refute_includes output, "onmouseover='alert(1)'"
  end
end
