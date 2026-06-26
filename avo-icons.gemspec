require_relative "lib/avo/icons/version"

Gem::Specification.new do |spec|
  spec.name        = "avo-icons"
  spec.version     = Avo::Icons::VERSION
  spec.authors     = [ "Paul Bob", "Adrian Marin" ]
  spec.email       = [ "avo@avohq.io" ]
  spec.homepage    = "https://avohq.io"
  spec.summary     = "A lightweight gem for serving icon SVGs effortlessly in Rails applications."
  spec.description = "A standalone Rails gem that provides Heroicons and Tabler Icons with smart caching and configurable search paths. Works with any Rails application."

  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "inline_svg"
end
