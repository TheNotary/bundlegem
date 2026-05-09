require 'find'
require 'fileutils'
require 'open3'
require 'shellwords'


module FoobarTemplates::CLI
  module DirToTemplate
    NO_PERSONAL_REPO_MSG = "Unable to convert to template, no personal templates repo exists.  Run `foobar_templates --setup-personal-templates` to get that setup.".freeze

    class << self

      def go(input: $stdin, output: $stdout)
        personal_dir = FoobarTemplates::CLI::SetupPersonalTemplatesRepo.personal_templates_dir
        if personal_dir.nil? || !File.directory?(personal_dir)
          output.puts NO_PERSONAL_REPO_MSG
          raise FoobarTemplates::CLIError
        end

        validate_inside_git_repo!(output: output)

        project_name = File.basename(Dir.pwd)
        default_category = read_existing_category(Dir.pwd) || "misc"

        template_folder_name = prompt(input, output, "Template folder name", project_name)
        validate_folder_name!(template_folder_name, output: output)

        category = prompt(input, output, "Category", default_category)

        dest = File.join(personal_dir, template_folder_name)

        if File.exist?(dest)
          output.puts "Error: a template already exists at #{dest}.  Remove it or rename your project before re-running."
          raise FoobarTemplates::CLIError
        end

        copy_tracked_files_to(dest)
        write_foobar_yml(dest, category)

        files_changed = Dir.chdir(dest) do
          FoobarTemplates::Core::DirToTemplate.🧙🪄! Find.find('.'), template_name: project_name
        end

        output.puts "Template created at: #{dest}"
        output.puts "Tip: review the new template directory and remove any files that aren't helpful as a starting point (build artifacts, secrets, lockfiles, large fixtures, etc.)."
        files_changed
      end

      private

      def validate_inside_git_repo!(output: $stdout)
        _stdout, _stderr, status = Open3.capture3("git rev-parse --is-inside-work-tree")
        return if status.success?
        output.puts "Error: --copy-to-templates must be run from within a git repository (it uses `git ls-files` to choose what to copy)."
        raise FoobarTemplates::CLIError
      end

      def copy_tracked_files_to(dest)
        # -c: cached/tracked, -o: untracked, --exclude-standard: respect .gitignore
        # This naturally excludes .git/ and gitignored files while keeping .gitignore.
        listing, _stderr, status = Open3.capture3("git ls-files -co --exclude-standard -z")
        if !status.success?
          $stderr.puts "Error: failed to enumerate files via `git ls-files`."
          raise FoobarTemplates::CLIError
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

      def ensure_foobar_yml(dest)
        path = File.join(dest, "foobar.yml")
        File.write(path, "category: misc\n") unless File.exist?(path)
      end

      def write_foobar_yml(dest, category)
        path = File.join(dest, "foobar.yml")
        if File.exist?(path)
          contents = File.read(path)
          if contents =~ /^category:.*$/
            contents = contents.sub(/^category:.*$/, "category: #{category}")
          else
            contents = "category: #{category}\n" + contents
          end
          File.write(path, contents)
        else
          File.write(path, "category: #{category}\n")
        end
      end

      def read_existing_category(dir)
        path = File.join(dir, "foobar.yml")
        return nil unless File.exist?(path)
        m = File.read(path).match(/^category:\s*(.+?)\s*$/)
        m && m[1].empty? ? nil : (m && m[1])
      end

      def prompt(input, output, message, default)
        output.print "#{message} [#{default}]: "
        answer = (input.gets || "").strip
        answer.empty? ? default : answer
      end

      def validate_folder_name!(name, output: $stdout)
        if name.nil? || name.empty? || name == "." || name == ".." || name.include?("/") || name.include?("\\")
          output.puts "Error: invalid template folder name: #{name.inspect}"
          raise FoobarTemplates::CLIError
        end
      end

    end
  end
end
