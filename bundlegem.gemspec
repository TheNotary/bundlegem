# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bundlegem/version'

version = Bundlegem::VERSION

Gem::Specification.new do |s|
  s.name          = "bundlegem"
  s.version       = version
  s.authors       = ["TheNotary"]
  s.email         = ["no@mail.plz"]
  s.summary       = %q{This gem makes more gems!}
  s.description   = %q{ This is a gem for making more gems!  I know!  It's like asking a genie for more wishes but it actually works!}
  s.homepage      = "https://github.com/thenotary/bundlegem"
  s.license       = "MIT"

  s.metadata["bug_tracker_uri"] = "https://github.com/TheNotary/bundlegem/issues"
  s.metadata["changelog_uri"] = "https://github.com/TheNotary/bundlegem/releases/tag/v#{version}"
  s.metadata["documentation_uri"] = "https://api.rubyonrails.org/v#{version}/"
  s.metadata["source_code_uri"] = "https://github.com/TheNotary/bundlegem/tree/v#{version}"

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "bundler", "~> 2.5"

  s.add_development_dependency "rake", "~> 13.2"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
end
