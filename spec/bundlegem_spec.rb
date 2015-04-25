require 'spec_helper'

describe Bundlegem do
  
  before :each do
    @mocked_home = "/tmp/bundlegem_mock_home"
    @template_root = "#{@mocked_home}/.bundlegem/gem_templates"
    @dst_dir = "/tmp/bundle_gem_dst_dir"

    reset_test_env
    FileUtils.chdir("/tmp/bundle_gem_dst_dir")
  end
  
  it 'has a version number' do
    expect(Bundlegem::VERSION).not_to be nil
  end

  it 'does something useful' do
    require 'bundlegem/cli'
  end

  it 'creates a config file if needed and lists properly' do
    create_user_defined_template
    
    list_output = Bundlegem.list
    
    expect(list_output).to eq " PREDEFINED:\n   newgem\n   service\n\n MISC:\n   empty_template\n\n"
    expect(File.exists?("#{ENV['HOME']}/.bundlegem")).to be true
  end
  
  it "lists with good categories" do
    category = "ARDUINO"
    create_user_defined_template(category)
    
    binding.pry
    
    list_output = Bundlegem.list
    
    expect(list_output.include?(category)).to be true
  end
  
  it "can generate the built-in gems fine" do
    options = {"bin"=>false, "ext"=>false, :coc=> false}
    gem_name = "tmp_gem" # gem name
    binding.pry
    Bundlegem.gem(options, gem_name)
  end
  
end
