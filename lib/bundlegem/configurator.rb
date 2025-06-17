require 'fileutils'
require 'yaml'

module Bundlegem

  class Configurator
    attr_accessor :config_file_data

    def initialize
      @config_directory_root = "#{ENV['HOME']}/.bundlegem"
      @config_file = "#{@config_directory_root}/config"
      @user_defined_templates_path = "#{@config_directory_root}/templates"

      create_config_file_if_needed!

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

    def collect_user_defined_templates
      user_definition_directory = @user_defined_templates_path
      templates = Dir.entries(user_definition_directory).select do |entry|
        File.directory?(File.join(user_definition_directory, entry)) and !(entry =='.' || entry == '..')
      end

      pairs = []
      templates.each do |template_path|
        # open the template_path and read the bundlegem.yml file to see what class of file it is
        # If there's no bundlegem.yml file in there, mark it misc

        template_config_path = "#{@user_defined_templates_path}/#{template_path}/bundlegem.yml"
        if File.exist?(template_config_path)
          obj = YAML.load_file(template_config_path, symbolize_names: true) || { category: "misc" }
          category = obj[:category]
        end

        pairs << {category => template_path.sub(/^template-/, "") }
      end
      pairs
    end

    def parse_out(key, config_txt)
      /#{key.to_s}:\s*([\w\s]*$)/ =~ config_txt
      $1.chomp
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
