require 'fileutils'

module Bundlegem
  
  class Configurator
    attr_accessor :user_defined_templates
    
    def initialize
      @config_directory_root = "#{ENV['HOME']}/.bundlegem"
      @config_file = "#{@config_directory_root}/config"
      @user_defined_templates_path = "#{@config_directory_root}/gem_templates"
      
      
      create_config_file_if_needed!
      
      # load configurations from config file if needed...
      # perhaps it would contain a list of remote templates specified by the user
    end

    def get_user_defined_template_names
      user_definition_directory = @user_defined_templates_path
      Dir.entries(user_definition_directory).select do |entry| 
        File.directory?(File.join(user_definition_directory, entry)) and !(entry =='.' || entry == '..') 
      end
    end
    
    def create_config_dir_if_needed!
      FileUtils.mkdir_p @user_defined_templates_path
      FileUtils.touch @config_file
    end
    
  end
end