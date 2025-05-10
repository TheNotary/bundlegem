require 'fileutils'

module Bundlegem

  # This class handles the logic for finding templates
  # in the user's dir, the gem's builtin templates
  # (and on the web some day)
  class TemplateManager
    class << self

      def internal_template_location() = File.expand_path("#{File.dirname(__FILE__)}/templates")
      def custom_template_location() = File.expand_path("~/.bundlegem/templates")
      def default_template_name() = "cli_gem"

      def get_template_src(options)
        template_name = options["template"] || default_template_name
        template_location = template_exists_within_repo?(template_name) ?
                        internal_template_location :
                        custom_template_location

        resolve_template_path(template_location, template_name)
      end

      def template_exists_within_repo?(template_name)
        file_in_source?(template_name) || file_in_source?("template-#{template_name}")
      end

      def resolve_template_path(location, name)
        basic = "#{location}/#{name}"
        prefixed = "#{location}/template-#{name}"

        return basic if File.exist?(basic)
        return prefixed if File.exist?(prefixed)

        basic # fallback, even if it doesn't exist, will be caught downstream
      end

      def try_template_src_locations(template_location, template_name)
        basic_form = "#{template_location}/#{template_name}"
        prefixed_form = "#{template_location}/template-#{template_name}"

        if File.exist?(basic_form)
          return basic_form
        elsif File.exist?(prefixed_form)
          return prefixed_form
        else
          "#{template_location}/#{template_name}"
        end
      end

      def find_in_source_paths(target)
        path = "#{__dir__}/templates/#{target}"
        File.exist?(path) ? path : target
      end

      # Get's path to 'target' from within the gem's "templates" folder
      # within the gem's source
      def file_in_source?(target)
        src_in_source_path = "#{File.dirname(__FILE__)}/templates/#{target}"
        File.exist?(src_in_source_path)
      end

    end
  end
end
