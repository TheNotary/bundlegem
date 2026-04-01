require 'fileutils'
require 'yaml'

module Bundlegem

  # This class handles the logic for finding templates
  # in the user's dir, the gem's builtin templates
  # (and on the web some day)
  class TemplateManager
    class TemplateResolutionError < StandardError; end

    class << self

      def internal_template_location() = File.expand_path("#{File.dirname(__FILE__)}/templates")
      def custom_template_location() = File.expand_path("~/.bundlegem/templates")
      def default_template_name() = "ruby-cli-gem"

      def get_template_src(options)
        template_name = options[:template] || default_template_name

        if template_exists_within_repo?(template_name)
          return resolve_template_path(internal_template_location, template_name)
        end

        custom_src = resolve_template_path(custom_template_location, template_name)
        return custom_src if File.exist?(custom_src)

        resolve_monorepo_leaf_template(custom_template_location, template_name) || custom_src
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

      def resolve_monorepo_leaf_template(root, requested_name)
        monorepo_roots = immediate_subdirectories(root).select { |dir| monorepo_directory?(dir) }
        return nil if monorepo_roots.empty?

        requested_leaf_name = requested_name.sub(/^template-/, "")
        leaf_paths = monorepo_roots.flat_map { |dir| collect_leaf_templates(dir) }
        matches = leaf_paths.select do |leaf_path|
          File.basename(leaf_path).sub(/^template-/, "") == requested_leaf_name
        end

        if matches.length > 1
          readable_paths = matches.map { |path| path.sub(/^#{Regexp.escape(root)}\//, "") }.sort.join(", ")
          raise TemplateResolutionError, "Ambiguous template name '#{requested_name}'. Matching leaf templates: #{readable_paths}. Rename one of the conflicting templates."
        end

        if matches.empty?
          readable_leaves = leaf_paths.map { |path| File.basename(path).sub(/^template-/, "") }.uniq.sort
          raise TemplateResolutionError, "Template '#{requested_name}' not found in monorepo leaf templates. Available leaf templates: #{readable_leaves.join(', ')}"
        end

        matches.first
      end

      def collect_leaf_templates(dir)
        config = load_template_config(dir)
        return [] if config.nil?

        if config[:monorepo] == true
          immediate_subdirectories(dir).flat_map { |child| collect_leaf_templates(child) }
        else
          [dir]
        end
      end

      def monorepo_directory?(dir)
        config = load_template_config(dir)
        !config.nil? && config[:monorepo] == true
      end

      def load_template_config(dir)
        path = File.join(dir, "bundlegem.yml")
        return nil unless File.exist?(path)

        raw = YAML.load_file(path, symbolize_names: true)
        raw.is_a?(Hash) ? raw : {}
      rescue StandardError
        {}
      end

      def immediate_subdirectories(dir)
        return [] unless File.exist?(dir)

        Dir.children(dir).filter_map do |entry|
          full_path = File.join(dir, entry)
          File.directory?(full_path) ? full_path : nil
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
