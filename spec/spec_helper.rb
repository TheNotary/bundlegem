$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bundlegem'
require 'fileutils'
require 'pry'

# Mock our home directory
ENV['HOME'] = "/tmp/bundlegem_mock_home"  


def create_user_defined_template(category = nil)
  template_root = "/tmp/bundlegem_mock_home/.bundlegem/gem_templates/empty_template"
  FileUtils.mkdir_p template_root
  
  File.open("#{template_root}/.bundlegem", "w+") do |f|
    f.puts "category: #{category}" unless category.nil?
  end
  
end


def clear_templates
  FileUtils.rm_rf "/tmp/bundlegem_mock_home/.bundlegem"
end