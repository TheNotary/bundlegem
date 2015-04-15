require 'spec_helper'

describe Bundlegem do
  
  before :each do
    ENV['HOME'] = "/tmp/bundlegem_mock_home"
  end
  
  it 'has a version number' do
    expect(Bundlegem::VERSION).not_to be nil
  end

  it 'does something useful' do
    require 'bundlegem/cli'
  
  it 'creates a config file if needed' do
    # invoke some code, like list templates
    # s = Bundlegem.list
    
    
  end
  
end
