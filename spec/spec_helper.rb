$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bundlegem'
require 'fileutils'
require 'pry'

# Mock our home directory

ENV['HOME'] = "/tmp/bundlegem_mock_home"




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
end

