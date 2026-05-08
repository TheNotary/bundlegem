$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$test_env = true
require 'bundlegem'
require 'bundlegem/cli/template_generator'
require 'fileutils'
require 'yaml'
require 'pry'

# Mock our home directory
ENV['HOME'] = "/tmp/bundlegem_mock_home"
ENV['SPEC_DATA_DIR'] = File.expand_path("./spec/data") # I fell into this from sloppy chdir handling, bad CLI/ API isolation.


def setup_mock_web_template
  mock_repo = "#{ENV['HOME']}/template-arduino.git"
  FileUtils.mkdir(mock_repo)
  FileUtils.touch("#{mock_repo}/README.md")

  `cd "#{mock_repo}" && git init && git add . && git commit -m "haxing"`

  # Update the config file so install_public_templates finds our mock repo
  config_path = "#{ENV['HOME']}/.bundlegem/config"
  config_data = YAML.load_file(config_path)
  config_data['public_templates'] = mock_repo
  File.write(config_path, "# Comments made to this file will not be preserved\n#{YAML.dump(config_data)}")
end

def remove_mock_web_template
  FileUtils.rm_rf("#{ENV['HOME']}/template-arduino.git")
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

def create_monorepo_template(path_segments, monorepo: true, category: nil)
  template_dir = File.join(@template_root, *path_segments)
  FileUtils.mkdir_p(template_dir)

  config = []
  config << "monorepo: true" if monorepo
  config << "category: #{category}" unless category.nil?
  File.write("#{template_dir}/bundlegem.yml", config.join("\n"))

  template_dir
end


def reset_test_env
  FileUtils.rm_rf @mocked_home
  FileUtils.rm_rf @dst_dir

  FileUtils.mkdir_p @dst_dir
  FileUtils.mkdir_p @template_root
  FileUtils.cd @dst_dir
  auth_settings  = '    git config --global user.email "you@example.com"'
  auth_settings += ' && git config --global user.name "Test"'

  `git config --global init.defaultBranch main && #{auth_settings}`

  # Write domain config to ~/.bundlegem/config instead of git config
  config_data = {
    'default_template' => 'cli_gem',
    'public_templates' => '',
    'registry_domain' => 'my-registry.example.com',
    'k8s_domain' => 'my-k8s.example.com',
    'repo_domain' => 'github.com',
  }
  FileUtils.mkdir_p "#{@mocked_home}/.bundlegem"
  File.write("#{@mocked_home}/.bundlegem/config", "# Comments made to this file will not be preserved\n#{YAML.dump(config_data)}")
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

def capture_stderr(&block)
  original_stderr = $stderr
  $stderr = fake = StringIO.new
  begin
    yield
  ensure
    $stderr = original_stderr
    $captured_stderr = fake.string
  end
  fake.string
end
