require 'find'
requle = nil
require 'fileutils'
require 'open3'
require 'shellwords'


module Bundlegem::CLI
  module DirToTemplate
    NO_PERSONAL_REPO_MSG = "Unable to convert to template, no personal templates repo exists.  Run `bundlegem --setup-personal-templates` to get that setup.".freeze

    class << self

      def go(output: $stdout)
        personal_dir = Bundlegem::CLI::SetupPersonalTemplatesRepo.personal_templates_dir
        if personal_dir.nil? || !File.directory?(personal_dir)
          output.puts NO_PERSONAL_REPO_MSG
          exit 1
        end

        validate_inside_git_repo!(output: output)

        template_name = File.basename(Dir.pwd)
        dest = File.join(personal_dir, template_name)

        if File.exist?(dest)
          output.puts "Error: a template already exists at #{dest}.  Remove it or rename your project before re-running."
          exit 1
        end

        copy_tracked_files_to(dest)
        ensure_bundlegem_yml(dest)

        files_changed = Dir.chdir(dest) do
          Bundlegem::Core::DirToTemplate.🧙🪄! Find.find('.'), template_name: template_name
        end

        output.puts "Template created at: #{dest}"
        output.puts "Tip: review the new template directory and remove any files that aren't helpful as a starting point (build artifacts, secrets, lockfiles, large fixtures, etc.)."
        files_changed
      end

      private

      def validate_inside_git_repo!(output: $stdout)
        _stdout, _stderr, status = Open3.capture3("git rev-parse --is-inside-work-tree")
        return if status.success?
        output.puts "Error: --to-template must be run from within a git repository (it uses `git ls-files` to choose what to copy)."
        exit 1
      end

      def copy_tracked_files_to(dest)
        # -c: cached/tracked, -o: untracked, --exclude-standard: respect .gitignore
        # This naturally excludes .git/ and gitignored files while keeping .gitignore.
        listing, _stderr, status = Open3.capture3("git ls-files -co --exclude-standard -z")
        if !status.success?
          $stderr.puts "Error: failed to enumerate files via `git ls-files`."
          exit 1
        end

        FileUtils.mkdir_p(dest)
        listing.split("\0").each do |rel_path|
          next if rel_path.empty?
          src = rel_path
          next unless File.file?(src) # skip submodule pointers, deleted files, etc.
          target = File.join(dest, rel_path)
          FileUtils.mkdir_p(File.dirname(target))
          FileUtils.cp(src, target)
        end
      end

      def ensure_bundlegem_yml(dest)
        path = File.join(dest, "bundlegem.yml")
        File.write(path, "category: misc\n") unless File.exist?(path)
      end

    end
  end
end
