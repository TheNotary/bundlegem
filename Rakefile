require 'rake'
require 'rspec/core/rake_task'

GEM_NAME = "foobar_templates"
GEM_SPEC = "#{GEM_NAME}.gemspec"

desc "Build #{GEM_NAME} gem"
task :build do
  system "gem build #{GEM_SPEC}"
  FileUtils.mkdir_p "pkg"
  FileUtils.mv Dir.glob("#{GEM_NAME}-*.gem"), "pkg/"
end

desc "Install #{GEM_NAME} gem locally"
task install: :build do
  system "gem install pkg/#{Dir.children('pkg').sort.last}"
end

desc "Build and push #{GEM_NAME} gem to RubyGems"
task release: :build do
  gem_file = Dir.glob("pkg/#{GEM_NAME}-*.gem").sort.last
  system "gem push #{gem_file}"
end

desc "Run unit specs"
RSpec::Core::RakeTask.new(:unit) do |t|
  t.rspec_opts = %w(-fd -c)
  t.pattern = "./spec/unit/**/*_spec.rb"
end

desc "Run integration specs that are very high level"
RSpec::Core::RakeTask.new(:integration) do |t|
  t.rspec_opts = %w(-fd -c)
  t.pattern = "./spec/integration/**/*_spec.rb"
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(-fd -c)
end

# this is for running tests that you've marked current... eg: it 'should work', current:  true do
RSpec::Core::RakeTask.new(:current) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--tag current']
end

# alias for current
RSpec::Core::RakeTask.new(:c) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--tag current']
end

task default:  :spec
task test:  :spec
