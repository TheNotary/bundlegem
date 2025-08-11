$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$test_env = true
require 'bundlegem'
require 'bundlegem/cli/gem'
require 'fileutils'
require 'pry'

# Mock our home directory
ENV['HOME'] = "/tmp/bundlegem_mock_home"
ENV['SPEC_DATA_DIR'] = File.expand_path("./spec/data") # I fell into this from sloppy chdir handling, bad CLI/ API isolation.


def setup_mock_web_template
  ENV['best_templates'] = "#{ENV['HOME']}/arduino.git"
  FileUtils.mkdir("#{ENV['HOME']}/arduino.git")
  FileUtils.touch("#{ENV['HOME']}/arduino.git/README.md")

  `cd "#{ENV['HOME']}/arduino.git" && git init && git add . && git commit -m "haxing"`
end

def remove_mock_web_template
  FileUtils.rm_rf("#{ENV['HOME']}/arduino.git")
end

def create_user_defined_template(category = nil, template_name = "empty_template")
  new_template_dir = "#{@template_root}/#{template_name}"

  # Creates the gem template (empty folder)
  FileUtils.mkdir_p new_template_dir

  # Writes the category
  File.open("#{new_template_dir}/bundlegem.yml", "w+") do |f|
    f.puts "category: #{category}" unless category.nil?
  end

  new_template_dir
end


def reset_test_env
  FileUtils.rm_rf @mocked_home
  FileUtils.rm_rf @dst_dir

  FileUtils.mkdir_p @dst_dir
  FileUtils.mkdir_p @template_root
  FileUtils.cd @dst_dir
  auth_settings = 'git config --global user.email "you@example.com" && git config --global user.name "Test"'

  `git config --global init.defaultBranch main && #{auth_settings}`
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
