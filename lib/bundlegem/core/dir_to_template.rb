require 'find'
require 'open3'
require 'shellwords'


module Bundlegem::Core::DirToTemplate
  class << self

    # Takes in a file_enumerator such as Find.find('.') and
    # renames all the files
    def 🧙🪄! file_enumerator, template_name: "asdf-pkg", dry_run: false
      files_changed = []
      file_enumerator.each do |path|
        next if should_skip?(path)

        conduct_pkg_name_to_template_variable_replacements!(path)

        new_path = "#{path}.tt"
        File.rename(path, new_path) unless dry_run
        repopulate_gitignore(path, new_path) unless dry_run

        files_changed << "Renamed: #{path} -> #{new_path}"
      end
      files_changed
    end

    private

    # Hack for putting the gitignore file back if it's been templatized...
    def repopulate_gitignore(path, new_path)
      if new_path == "./.gitignore.tt"
        FileUtils.cp(new_path, path)
      end
    end

    def conduct_pkg_name_to_template_variable_replacements!(path)
      # TODO: Conduct text replacements:
      #
      #   'asdf-pkg' -> '<%=config[:name]%>'
      #   'asdf_pkg' -> '<%=config[:underscored_name]%>'
      #   'ASDF_PKG' -> '<%=config[:screamcase_name]%>'
    end

    def should_skip?(path)
      !File.file?(path) ||              # skip directories
        path.end_with?('.tt') ||        # skip if the file is a .tt already
        File.exist?("#{path}.tt") ||    # skip if a .tt variant of this file exists
        path.start_with?('./.git/') ||  # skip the .git directory
        ignored_by_git?(path) ||        # skip things that are gitignored
        path == "./bundlegem.yml"          # skip the bundlegem.yml file
    end

    def validate_working_directory!
      # check for the existence of a bundlegem.yml file which won't ordinarily exist
      if !File.exist?("bundlegem.yml")
        raise "error: bundlegem.yml file not found in current directory.  Create it or run this command in the folder you thought you were in."
      end
    end

    def ignored_by_git?(path)
      stdout, _, status = Open3.capture3("git check-ignore #{Shellwords.escape(path)}")
      status.success? && !stdout.strip.empty?
    end

  end
end
