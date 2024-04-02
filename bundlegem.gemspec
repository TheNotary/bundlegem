# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bundlegem/version'

Gem::Specification.new do |spec|
  spec.name          = "bundlegem"
  spec.version       = Bundlegem::VERSION
  spec.authors       = ["TheNotary"]
  spec.email         = ["no@mail.plz"]
  spec.summary       = %q{this gem makes more gems!}
  spec.description   = %q{ I KNOW!  ISN'T THAT LIKE WISHING FOR MORE WISHES!}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "0.19.1"
  spec.add_dependency "bundler", "~> 2.5"

  #spec.add_development_dependency "bundler"#, "~> 1.8"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
