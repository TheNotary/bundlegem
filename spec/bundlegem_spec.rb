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

  it 'creates a config file if needed and lists properly' do
    create_user_defined_template

    list_output = Bundlegem.list

    expect(list_output).to eq " PREDEFINED:\n * cli_gem       (default)\n   c_extension_gem\n\n MISC:\n   empty_template\n\n"
    expect(File.exist?("#{ENV['HOME']}/.bundlegem")).to be true
  end

  it "lists with good categories" do
    category = "ARDUINO"
    create_user_defined_template(category)

    list_output = Bundlegem.list
    expect(list_output.include?(category)).to be true
  end

  # This bulids the default gem template
  it "can generate the default built-in gem fine" do
    options = {"bin"=>false, "ext"=>false, :coc=> false}
    gem_name = "tmp_gem"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File.exist?("#{@dst_dir}/#{gem_name}/README.md")).to be_truthy
  end

  it "can generate the c_ext gem fine" do
    options = {"bin"=>false, "ext"=>false, :coc=> false, "template" => "c_extension_gem"}
    gem_name = "tmp_gem"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File.exist?("#{@dst_dir}/#{gem_name}/ext/tmp_gem/#{gem_name}.c")).to be_truthy
  end

  it "has a useful dynamically_generate_templates metho" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::Gem.new(options, gem_name)

    src_dst_map = my_gem.send('dynamically_generate_template_directories')

    expect(src_dst_map['#{name}']).to eq "good-dog"
    expect(src_dst_map['#{underscored_name}']).to eq '#{underscored_name}'
    expect(src_dst_map['simple_dir']).to eq 'simple_dir'
  end

  it "has a useful dynamically_generate_templates method" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"
    my_gem = Bundlegem::CLI::Gem.new(options, gem_name)

    src_dst_map = my_gem.send('dynamically_generate_templates')

    expect(src_dst_map['#{name}/keep.tt']).to eq "good-dog/keep"
    expect(src_dst_map['#{name}.rb.tt']).to eq 'good-dog.rb'
    expect(src_dst_map['#{underscored_name}/keep.tt']).to eq 'good_dog/keep'
    expect(src_dst_map['simple_dir/keep.tt']).to eq 'simple_dir/keep'
  end

  it "has a test proving every interpolation in one file" do
    options = { "bin"=>false, "ext"=>false, :coc=> false, "template" => "test_template" }
    gem_name = "good-dog"

    capture_stdout { Bundlegem.gem(options, gem_name) }
    expect(File.read("#{@dst_dir}/#{gem_name}/#{gem_name}.rb")).to eq File.read("#{ENV['SPEC_DATA_DIR']}/variable_manifest_test.rb")
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
      expect(File.exist?("#{ENV['HOME']}/.bundlegem/templates/arduino/README.md")).to be_truthy
    end

  end

end
