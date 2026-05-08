require 'find'
require 'open3'
require 'shellwords'


module Bundlegem::Core::DirToTemplate
  class << self

    # Takes in a file_enumerator such as Find.find('.') and
    # performs literal string replacements of project name variants
    # with foo-bar template placeholders
    def 🧙🪄! file_enumerator, template_name: "asdf-pkg", dry_run: false
      replacements = build_replacement_pairs(template_name)
      files_changed = []
      file_enumerator.each do |path|
        next if should_skip?(path)

        conduct_pkg_name_to_template_variable_replacements!(path, replacements) unless dry_run

        files_changed << "Processed: #{path}"
      end      
      files_changed
    end

    private

    def build_replacement_pairs(template_name)
      underscored = template_name.tr('-', '_')
      screamcase  = underscored.upcase
      pascal      = underscored.split('_').map(&:capitalize).join
      camel       = pascal.sub(/^./, &:downcase)

      # Order: longer/more-specific patterns first to avoid partial matches
      [
        [screamcase,    'FOO_BAR'],
        [pascal,        'FooBar'],
        [camel,         'fooBar'],
        [template_name, 'foo-bar'],
        [underscored,   'foo_bar'],
      ]
    end

    def conduct_pkg_name_to_template_variable_replacements!(path, replacements)
      content = File.read(path)
      original = content.dup

      replacements.each do |find, replace|
        content.gsub!(find, replace)
      end

      File.write(path, content) if content != original
    end

    def should_skip?(path)
      !File.file?(path) ||               # skip directories
        path.start_with?('./.git/') ||   # skip the .git directory
        path == './.gitignore' ||        # skip .gitignore (must remain for git to work)
        ignored_by_git?(path) ||         # skip things that are gitignored
        path == "./bundlegem.yml"        # skip the bundlegem.yml file
    end

    def ignored_by_git?(path)
      stdout, _, status = Open3.capture3("git check-ignore #{Shellwords.escape(path)}")
      status.success? && !stdout.strip.empty?
    end

  end
end
