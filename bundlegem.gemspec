# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bundlegem/version'

Gem::Specification.new do |spec|
  spec.name          = "bundlegem"
  spec.version       = Bundlegem::VERSION
  spec.authors       = ["TheNotary"]
  spec.email         = ["no@mail.plz"]
  spec.summary       = %q{This gem makes more gems!}
  spec.description   = %q{ This is a gem for making more gems.  I KNOW!  ISN'T THAT LIKE WISHING FOR MORE WISHES!}
  spec.homepage      = "https://github.com/thenotary/bundlegem"
  spec.license       = "MIT"

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/TheNotary/bundlegem/issues",
    "changelog_uri"     => "https://github.com/TheNotary/bundlegem/releases/tag/v#{version}",
    "documentation_uri" => "https://api.rubyonrails.org/v#{version}/",
    "source_code_uri"   => "https://github.com/TheNotary/bundlegem/tree/v#{version}",
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "0.19.1"
  spec.add_dependency "bundler", "~> 2.5"
  spec.add_dependency "ostruct"
  spec.add_dependency "reline"

  #spec.add_development_dependency "bundler"#, "~> 1.8"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
