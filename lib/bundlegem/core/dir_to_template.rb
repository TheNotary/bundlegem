require 'find'
require 'open3'
require 'shellwords'


module Bundlegem::Core::DirToTemplate
  class << self

    def go
      validate_working_directory!
      file_enumerator = Find.find('.')

      🧙🪄! file_enumerator
    end

    def 🧙🪄! file_enumerator, dry_run: false
      files_changed = []
      file_enumerator.each do |path|
        next if should_skip?(path)

        new_path = "#{path}.tt"
        File.rename(path, new_path) unless dry_run
        files_changed << "Renamed: #{path} -> #{new_path}"
      end
      files_changed
    end

    private

    def should_skip?(path)
      return false if path == "./.gitignore" && !File.exist?("#{path}.tt")

      !File.file?(path) ||              # skip directories
        path.end_with?('.tt') ||        # skip if the file is a .tt already
        File.exist?("#{path}.tt") ||    # skip if a .tt variant of this file exists
        path.start_with?('./.git') ||   # skip the .git directory
        ignored_by_git?(path) ||        # skip things that are gitignored
        path == "./.bundlegem"          # skip the .bundlegem file
    end

    def validate_working_directory!
      # check for the existence of a .bundlegem file which won't ordinarily exist
      if !File.exist?(".bundlegem")
        raise "error: .bundlegem file not found in current directory.  Create it or run this command in the folder you thought you were in."
      end
    end

    def ignored_by_git?(path)
      stdout, _, status = Open3.capture3("git check-ignore #{Shellwords.escape(path)}")
      status.success? && !stdout.strip.empty?
    end

  end
end
