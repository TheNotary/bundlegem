require 'fileutils'
require 'yaml'

module Bundlegem

  class Configurator
    attr_accessor :user_defined_templates, :user_downloaded_templates, :config_file_data

    def initialize
      @config_directory_root = "#{ENV['HOME']}/.bundlegem"
      @config_file = "#{@config_directory_root}/config"
      @user_defined_templates_path = "#{@config_directory_root}/templates"

      create_config_file_if_needed!

      @user_defined_templates = get_user_defined_templates
      @user_downloaded_templates = get_user_downloaded_templates

      # load configurations from config file
      @config_file_data = YAML.load_file @config_file
    end

    def default_template
      @config_file_data["default_template"]
    end

    def default_template=(val)
      @config_file_data["default_template"] = val
      File.write(@config_file, "# Comments made to this file will not be preserved\n#{YAML.dump(@config_file_data)}")
    end

    def built_in_templates

    end

    # not implemented yet
    def get_user_downloaded_templates
      []
    end

    def get_user_defined_templates
      user_definition_directory = @user_defined_templates_path
      template_dirs = Dir.entries(user_definition_directory).select do |entry|
        File.directory?(File.join(user_definition_directory, entry)) and !(entry =='.' || entry == '..')
      end

      pairs = []
      template_dirs.each do |dir|
        # open the dir and read the .bundlegem file to see what class of file it is
        # If there's no .bundlegem file in there, mark it misc

        begin
          f = File.read("#{@user_defined_templates_path}/#{dir}/.bundlegem")
          /category:\s*([\w\s]*$)/ =~ f

          category = $1.chomp
        rescue
          category = "MISC"
        end

        category = "MISC" if category.nil?

        pairs << {category => dir }
      end
      pairs
    end

    def create_config_file_if_needed!
      FileUtils.mkdir_p @user_defined_templates_path
      FileUtils.cp("#{SOURCE_ROOT}/config/config", @config_file) unless File.exist? @config_file
    end

    def create_new_template(template_name)
      puts "i'm still a stub"
    end

  end
end
