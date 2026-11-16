require "test_helper"
require "tmpdir"

class NextVersionTest < ActiveSupport::TestCase
  SCRIPT = File.expand_path("../bin/next_version", __dir__)
  ICONS = "lib/assets/svgs/tabler/outline"

  # The developer's global git config (signing, hooks) must not reach the scratch repository.
  GIT_ENV = {
    "GIT_CONFIG_GLOBAL" => File::NULL, "GIT_CONFIG_NOSYSTEM" => "1",
    "GIT_AUTHOR_NAME" => "Test", "GIT_AUTHOR_EMAIL" => "test@example.com",
    "GIT_COMMITTER_NAME" => "Test", "GIT_COMMITTER_EMAIL" => "test@example.com"
  }

  setup do
    @repo = Dir.mktmpdir
    write "#{ICONS}/user.svg", "<svg>user</svg>"
    write "Gemfile.lock", "inline_svg (1.10.0)"
    git "init", "--quiet"
    commit
    git "tag", "v1.2.3"
  end

  teardown { FileUtils.remove_entry(@repo) }

  test "removing an icon, renaming included, releases a major version" do
    git "mv", "#{ICONS}/user.svg", "#{ICONS}/user-circle.svg"
    commit

    assert_equal "2.0.0", next_version
  end

  test "adding an icon releases a minor version" do
    write "#{ICONS}/bell.svg", "<svg>bell</svg>"
    commit

    assert_equal "1.3.0", next_version
  end

  test "changing a shipped file releases a patch version" do
    write "#{ICONS}/user.svg", "<svg>user, redrawn</svg>"
    commit

    assert_equal "1.2.4", next_version
  end

  test "a lockfile-only change releases nothing" do
    write "Gemfile.lock", "inline_svg (1.10.1)"
    commit

    assert_equal "", next_version
  end

  private

  def write(path, content)
    FileUtils.mkdir_p(File.join(@repo, File.dirname(path)))
    File.write(File.join(@repo, path), content)
  end

  def commit
    git "add", "--all"
    git "commit", "--quiet", "--message", "change"
  end

  def git(*args)
    system(GIT_ENV, "git", *args, chdir: @repo, exception: true)
  end

  def next_version
    IO.popen(GIT_ENV, [ RbConfig.ruby, SCRIPT ], chdir: @repo, &:read).strip
  end
end
