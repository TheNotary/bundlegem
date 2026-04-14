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
      save_config!
    end

    def domain(key)
      @config_file_data[key.to_s]
    end

    def set_domain(key, value)
      @config_file_data[key.to_s] = value
      save_config!
    end

    def collect_user_defined_templates
      immediate_subdirectories(@user_defined_templates_path).flat_map do |template_dir|
        collect_templates_from_path(template_dir)
      end
    end

    def create_config_file_if_needed!
      FileUtils.mkdir_p @user_defined_templates_path
      FileUtils.cp("#{SOURCE_ROOT}/config/config", @config_file) unless File.exist? @config_file
    end

    private

    def collect_templates_from_path(template_dir)
      config = read_template_config(template_dir)

      if monorepo_template?(config)
        immediate_subdirectories(template_dir).flat_map do |child_dir|
          collect_templates_from_path(child_dir)
        end
      else
        category = config[:category] || "misc"
        [{ category => File.basename(template_dir).sub(/^template-/, "") }]
      end
    end

    def monorepo_template?(config)
      config[:monorepo] == true
    end

    def read_template_config(template_dir)
      template_config_path = File.join(template_dir, "bundlegem.yml")
      return {} unless File.exist?(template_config_path)

      raw_config = YAML.load_file(template_config_path, symbolize_names: true)
      raw_config.is_a?(Hash) ? raw_config : {}
    rescue StandardError
      {}
    end

    def immediate_subdirectories(dir)
      Dir.children(dir).filter_map do |child_dir|
        # Skip hidden files and dirs like .ds_store, etc.
        if child_dir.start_with?(".")
          nil
        else
          dir_path = File.join(dir, child_dir)
          File.directory?(dir_path) ? dir_path : nil
        end
      end
    end

    def save_config!
      File.write(@config_file, "# Comments made to this file will not be preserved\n#{YAML.dump(@config_file_data)}")
    end

  end
end
