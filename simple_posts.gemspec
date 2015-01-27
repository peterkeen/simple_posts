$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "simple_posts/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "simple_posts"
  s.version     = SimplePosts::VERSION
  s.authors     = ["Pete Keen"]
  s.email       = ["peter.keen@bugsplat.info"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of SimplePosts."
  s.description = "TODO: Description of SimplePosts."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4"
  s.add_dependency "redcarpet"
  s.add_dependency "rouge"
end
