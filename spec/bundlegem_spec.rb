require 'spec_helper'

describe Bundlegem do
  it 'has a version number' do
    expect(Bundlegem::VERSION).not_to be nil
  end

  it 'does something useful' do
    require 'bundlegem/cli'
    binding.pry

  end
end
