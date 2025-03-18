$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$test_env = true
require 'bundlegem'
require 'bundlegem/cli'
require 'bundlegem/cli/gem'
require 'fileutils'
require 'pry'

# Mock our home directory
ENV['HOME'] = "/tmp/bundlegem_mock_home"


def setup_mock_web_template
  ENV['best_templates'] = "#{ENV['HOME']}/arduino.git"
  FileUtils.mkdir("#{ENV['HOME']}/arduino.git")
  FileUtils.touch("#{ENV['HOME']}/arduino.git/README.md")

  auth_settings = 'git config --local user.email "you@example.com" && git config --local user.name "test"'
  `cd "#{ENV['HOME']}/arduino.git" && git init &&  git add . && #{auth_settings} && git commit -m "haxing"`
end

def remove_mock_web_template
  FileUtils.rm_rf("#{ENV['HOME']}/arduino.git")
end

def create_user_defined_template(category = nil)
  new_templates_dir = "#{@template_root}/empty_template"

  # Creates the gem template (empty folder)
  FileUtils.mkdir_p new_templates_dir

  # Writes the category
  File.open("#{new_templates_dir}/.bundlegem", "w+") do |f|
    f.puts "category: #{category}" unless category.nil?
  end
end


def reset_test_env
  FileUtils.rm_rf @mocked_home
  FileUtils.rm_rf @dst_dir

  FileUtils.mkdir_p @dst_dir
  FileUtils.mkdir_p @template_root
  FileUtils.cd @dst_dir
  `git config --global init.defaultBranch main`
end

# squelch stdout
# usage capture_stdout { a_method(a_signal.new, a_model, a_helper) }
def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
 fake.string
end
