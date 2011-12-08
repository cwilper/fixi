# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fixi/version"

Gem::Specification.new do |s|
  s.name        = "fixi"
  s.version     = Fixi::VERSION
  s.authors     = ["Chris Wilper"]
  s.email       = ["cwilper@gmail.com"]
  s.homepage    = ""
  s.summary     = "A fixity tracker utility"
  s.description = "Keeps an index of checksums and lets you update and verify them"

  s.rubyforge_project = "fixi"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"

  s.add_runtime_dependency "trollop"
  s.add_runtime_dependency "sqlite3-ruby"
end
