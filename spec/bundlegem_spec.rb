require 'spec_helper'

describe Bundlegem do
  
  before :each do
    clear_templates
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
    
    expect(list_output).to eq " PREDEFINED:\n   default\n   service\n\n MISC:\n   empty_template\n\n"
    expect(File.exists?("#{ENV['HOME']}/.bundlegem")).to be true
  end
  
end
