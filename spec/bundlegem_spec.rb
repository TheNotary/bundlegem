require 'spec_helper'

describe Bundlegem do
  before :each do
    @mocked_home = "/tmp/bundlegem_mock_home"
    @template_root = "#{@mocked_home}/.bundlegem/templates"
    @dst_dir = "/tmp/bundle_gem_dst_dir"

    reset_test_env
    FileUtils.chdir(@dst_dir)
  end

  it 'has a version number' do
    expect(Bundlegem::VERSION).not_to be nil
  end

  # List

  it 'creates a config file if needed and lists properly' do
    create_user_defined_template

    list_output = Bundlegem.list

    expect(list_output).to eq " MISC:\n   empty_template\n\n"
    expect(File).to exist("#{ENV['HOME']}/.bundlegem")
  end

  it "lists with good categories" do
    category = "ARDUINO"
    create_user_defined_template(category)

    list_output = Bundlegem.list
    expect(list_output).to include category
  end

  it "lists omit the prefix 'template-' if present in repo" do
    category = "ANYTHING"
    full_template_name = "template-happy-burger"
    create_user_defined_template(category, "template-happy-burger")

    list_output = Bundlegem.list
    # expect(list_output.include?(full_template_name)).to be false
    expect(list_output).not_to include full_template_name
    expect(list_output).to include "happy-burger"
  end

  # Generate

  # This bulids the default gem template
  it "can generate the default built-in gem fine" do
    options = {"bin"=>false, "ext"=>false, :coc=> false}
    gem_name = "tmp_gem"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File).to exist("#{@dst_dir}/#{gem_name}/README.md")
  end

  it "can generate the c_ext gem fine" do
    options = {"bin"=>false, "ext"=>false, :coc=> false, "template" => "c_extension_gem"}
    gem_name = "tmp_gem"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File).to exist("#{@dst_dir}/#{gem_name}/ext/tmp_gem/#{gem_name}.c")
  end

  it "finds the template-test template even if the template- prefix was omitted" do
    options = {"bin"=>false, "ext"=>false, :coc=> false, "template" => "test"}
    gem_name = "tmp_gem"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File).to exist("#{@dst_dir}/#{gem_name}/test_confirmed")
    expect(File).to exist("#{@dst_dir}/#{gem_name}/.vscode/launch.json")
  end

  it "has a useful dynamically_generate_template_directories method" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::Gem.new(options, gem_name)

    src_dst_map = my_gem.send('dynamically_generate_template_directories')

    expect(src_dst_map['#{name}']).to eq "good-dog"
    expect(src_dst_map['#{underscored_name}']).to eq "good_dog"
    expect(src_dst_map['simple_dir']).to eq 'simple_dir'
  end

  it "returns the expected interpolated string when substitute_template_values is called" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::Gem.new(options, gem_name)

    short_path = '#{name}'
    long_path = 'hello/#{name}/blah/#{name}'

    short_interpolated_string = my_gem.send('substitute_template_values', short_path)
    expect(short_interpolated_string).to eq gem_name

    long_interpolated_string = my_gem.send('substitute_template_values', long_path)
    expect(long_interpolated_string).to eq "hello/good-dog/blah/good-dog"
  end

  it "has a useful dynamically_generate_templates_files method" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::Gem.new(options, gem_name)

    src_dst_map = my_gem.send('dynamically_generate_templates_files')

    expect(src_dst_map['#{name}/keep.tt']).to eq "good-dog/keep"
    expect(src_dst_map['#{name}.rb.tt']).to eq 'good-dog.rb'
    expect(src_dst_map['#{underscored_name}/keep.tt']).to eq 'good_dog/keep'
    expect(src_dst_map['simple_dir/keep.tt']).to eq 'simple_dir/keep'
  end

  it "won't generate template files that are listed under the gitignore" do
    template_dir = create_user_defined_template("testing", "template-user-supplied")
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "template-user-supplied" }
    gem_name = "good-dog"

    File.write("#{template_dir}/.gitignore", "node_modules/")
    File.write("#{template_dir}/README.md.tt", "Hello")
    FileUtils.mkdir("#{template_dir}/node_modules")
    File.write("#{template_dir}/node_modules/dont_template.rb.tt", "I must not be interpretted")
    `git init #{template_dir}`

    capture_stdout { Bundlegem.gem(options, gem_name) }

    expect(File).not_to exist "#{@dst_dir}/#{gem_name}/node_modules/dont_template.rb"
    expect(File).not_to exist "#{@dst_dir}/#{gem_name}/node_modules"
  end

  it "executes the bootstrap_command if supplied" do
    template_dir = create_user_defined_template("testing", "template-user-supplied")
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "template-user-supplied" }
    gem_name = "good-dog"

    File.write("#{template_dir}/bundlegem.yml", "bootstrap_command: echo hihihi")
    File.write("#{template_dir}/README.md.tt", "# Readme...")
    `git init #{template_dir}`

    output = capture_stdout { Bundlegem.gem(options, gem_name) }

    expect(output).to include "hihihi"
  end

  it "has a test proving every interpolation in one file" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File.read("#{@dst_dir}/#{gem_name}/#{gem_name}.rb")).to eq File.read("#{ENV['SPEC_DATA_DIR']}/variable_manifest_test.rb")
  end

  it "has config[:unprefixed_name] removing purpose-tool- from name" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "tool-go-good-dog"
    my_gem = Bundlegem::CLI::Gem.new(options, gem_name)

    config = my_gem.build_interpolation_config

    expect(config[:unprefixed_name]).to eq "good-dog"
  end

  describe "install best templates" do
    before :each do
      setup_mock_web_template
    end
    after :each do
      remove_mock_web_template
    end

    it "can download best templates from the web" do
      capture_stdout { Bundlegem.install_best_templates }
      expect(File).to exist("#{ENV['HOME']}/.bundlegem/templates/template-arduino/README.md")
    end
  end

end
