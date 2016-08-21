require 'fileutils'

module Bundlegem

  # This class handles the logic for finding templates
  # in the user's dir, the gem's builtin templates
  # (and on the web some day)
  class TemplateManager

    class << self

      def create_new_template(template_name)

      end


      def get_default_template_name
        "newgem"
      end

      def get_template_src(options)
        template_name = options["template"].nil? ? get_default_template_name : options["template"]

        if template_exists_within_repo?(template_name)
          gem_template_location = get_internal_template_location
        else
          gem_template_location = File.expand_path("~/.bundlegem/gem_templates")
        end
        template_src = "#{gem_template_location}/#{template_name}"
      end


      def get_internal_template_location
        File.expand_path("#{File.dirname(__FILE__)}/templates")
      end

      def template_exists_within_repo?(template_name)
        TemplateManager.file_in_source?(template_name)
      end

      #
      # EDIT:  Reworked from Thor to not rely on Thor (or do so much unneeded stuff)
      #
      def find_in_source_paths(target)
        src_in_source_path = "#{File.dirname(__FILE__)}/templates/#{target}"
        return src_in_source_path if File.exists?(src_in_source_path)
        target # failed, hopefully full path to a user specified gem template file
      end

      # Get's path to 'target' from within the gem's "templates" folder
      # within the gem's source
      def file_in_source?(target)
        src_in_source_path = "#{File.dirname(__FILE__)}/templates/#{target}"
        File.exists?(src_in_source_path)
      end

    end
  end
end
