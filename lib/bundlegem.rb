require "bundlegem/version"
require "bundlegem/strings"
require 'bundlegem/configurator'
require 'bundlegem/template_manager'

require 'bundlegem/cli'

SOURCE_ROOT = File.expand_path("#{File.dirname(__FILE__)}/..")

module Bundlegem

  class << self

    # lists available templates
    def list
      configurator = Configurator.new
      # search through builtin
      available_templates = [ { "predefined" => "newgem" },
                              { "predefined" => "service" }]

      # search through user downloaded
      available_templates += configurator.user_downloaded_templates

      # search through user defined
      available_templates += configurator.user_defined_templates

      available_templates = group_hashes_by_key(available_templates)
      output_string = convert_grouped_hashes_to_output(available_templates)

      mark_default_template(output_string, configurator.default_template)
    end

    def gem(options, gem_name)
      require 'bundlegem/cli'
      require 'bundlegem/cli/gem'

      Bundlegem::CLI::Gem.new(options, gem_name).run
    end

    def new_template(args)
      template_name = args[1]
      template_name = prompt_for_template_name if template_name.nil?

      # Copy newgem from within the repo to ~/.bundlegem/templates/#{template_name}
      TemplateManager.create_new_template(template_name)
    end

    def prompt_for_template_name
      puts "Please specify a name for your template:  "
      template_name = STDIN.gets.chomp.strip.gsub(" ", "_")
    end

    # input:  [ { "predefined" => "default" },
    #           { "MISC" => "my_thing" },
    #           { "prdefined" => "service" }
    #         ]
    #
    # output: [ { "predefined" => ["default", "service"] },
    #           { "MISC" => ["my_thing"] }
    #         ]
    #
    def group_hashes_by_key(available_templates)
      h = {}
      available_templates.each do |hash|
        k = hash.first.first
        v = hash.first.last
        h[k] = [] unless h.has_key?(k)
        h[k] << v
      end
      h
    end

    # input:  [ { "predefined" => ["default", "service"] },
    #           { "MISC" => ["my_thing"] }
    #         ]
    def convert_grouped_hashes_to_output(available_templates)
      s = ""
      available_templates.each do |hash|
        k = hash.first.upcase
        a = hash.last
        s << " #{k}:\n"
        a.each do |el|
          s << "   #{el}\n"
        end
        s << "\n"
      end
      s
    end

    def mark_default_template(output_string, default_template)
      output_string.lines.reverse.map do |l|
        if l.strip == default_template
          l[1]= "*"
          "#{l.chomp}       (default)\n"
        else
          l
        end
      end.reverse.join
    end

    def which(executable)
      if File.file?(executable) && File.executable?(executable)
        executable
      elsif ENV['PATH']
        path = ENV['PATH'].split(File::PATH_SEPARATOR).find do |p|
          abs_path = File.join(p, executable)
          File.file?(abs_path) && File.executable?(abs_path)
        end
        path && File.expand_path(executable, path)
      end
    end

    def install_best_templates
      puts "Downloading templates from the following locations: #{ENV['best_templates']}"
      ENV['best_templates'].split.each do |url|
        uri = URI.parse(url)
        template_folder_name = File.basename(uri.path).sub(/\.git$/, "")
        if !File.exists?(template_folder_name)
          `cd #{ENV['HOME']}/.bundlegem/templates && git clone #{url}`
        else
          # TODO:
          # Prompt to update the repo if they have a clean working state.
        end
      end
    end

  end

end
