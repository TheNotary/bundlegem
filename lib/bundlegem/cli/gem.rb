require 'pathname'
require 'yaml'
require 'erb'

$TRACE = false

module Bundlegem::CLI
  class Gem
    attr_reader :options, :gem_name, :name, :target

    def initialize(options, gem_name)
      @options = options
      @gem_name = resolve_name(gem_name)

      @name = @gem_name
      @target = Pathname.pwd.join(gem_name)
      @template_src = ::Bundlegem::TemplateManager.get_template_src(options)

      @tconf = load_template_configs

      validate_ext_name if options[:ext] # FIXME: Useless now?
    end

    def build_interpolation_config
      title = name.tr('-', '_').split('_').map(&:capitalize).join(" ")
      pascal_name = name.tr('-', '_').split('_').map(&:capitalize).join
      unprefixed_name = name.sub(/^#{@tconf[:prefix]}/, '')
      underscored_name = name.tr('-', '_')
      constant_name = name.split('_').map{|p| p[0..0].upcase + p[1..-1] unless p.empty?}.join
      constant_name = constant_name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/
      constant_array = constant_name.split('::')
      git_user_name = `git config user.name`.chomp
      git_user_email = `git config user.email`.chomp

      # git_repo_domain = provider.com
      git_repo_domain = `git config user.repo-domain`.chomp

      if git_repo_domain.empty?
        git_repo_domain = "github.com"
      end

      if git_user_name.empty?
        puts "Error: git config user.name didn't return a value.  You'll probably want to make sure that's configured with your github username:"
        puts ""
        puts "git config --global user.name YOUR_GH_NAME"
        exit 1
      else
        # git_repo_path = provider.com/user/name
        git_repo_path = "#{git_repo_domain}/#{git_user_name}/#{name}".downcase # downcasing for languages like go that are creative
      end

      # git_repo_url = https://provider.com/user/name
      git_repo_url = "https://#{git_repo_domain}/#{git_user_name}/#{name}"

      config = {
        :name             => name,
        :title            => title,
        :unprefixed_name  => unprefixed_name,
        unprefixed_pascal: unprefixed_name.tr('-', '_').split('_').map(&:capitalize).join,
        underscored_name:  underscored_name,
        :pascal_name      => pascal_name,
        :camel_name       => pascal_name.sub(/^./, &:downcase),
        :screamcase_name  => name.tr('-', '_').upcase,
        :namespaced_path  => name.tr('-', '/'),
        :makefile_path    => "#{underscored_name}/#{underscored_name}",
        :constant_name    => constant_name,
        :constant_array   => constant_array,
        :author           => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
        :email            => git_user_email.empty? ? "TODO: Write your email address" : git_user_email,
        :git_repo_domain  => git_repo_domain,
        :git_repo_url     => git_repo_url,
        :git_repo_path    => git_repo_path,
        :template         => @options[:template],
        :test             => @options[:test],
        :ext              => @options[:ext],
        :bin              => @options[:bin],
        :bundler_version  => bundler_dependency_version
      }
    end

    def config
      @config ||= build_interpolation_config
    end

    def run
      puts "Beginning run" if $TRACE
      raise_project_with_that_name_already_exists! if File.exist?(target)

      puts "ensure_safe_gem_name" if $TRACE
      ensure_safe_gem_name(name, config[:constant_array])

      template_src = match_template_src

      puts "dynamically_generate_template_directories" if $TRACE
      time_it("dynamically_generate_template_directories") do
        @template_directories = dynamically_generate_template_directories
      end

      puts "dynamically_generate_templates_files" if $TRACE
      templates = dynamically_generate_templates_files

      puts "Creating new project folder '#{name}'\n\n"
      create_template_directories(@template_directories, target)

      templates.each do |src, dst|
        template("#{template_src}/#{src}", target.join(dst), config)
      end

      # Bundler.ui.info "Initializing git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }

      if @tconf[:bootstrap_command]
        puts "Executing bootstrap_command"
        cmd = safe_gsub_template_variables(@tconf[:bootstrap_command])
        puts cmd
        Dir.chdir(target) do
          `#{cmd}`
        end
      end

      puts "\nComplete."
    end

    private

    def safe_gsub_template_variables(user_string)
      user_string.gsub(/\#{\s*config\[\s*:(\w+)\s*\]\s*}/) { |m| config[$1.to_sym] }
    end

    # TODO: Extract these notes to the docs or delete them
    # The language and purpose configurations of the bundlegem.yml file
    # can be used to make sure when you create a folder named
    # `bundlegem -t blah tool-go-ollama-find`, the internal name
    # that the app has for itself can become simply `ollama-find`, dropping the prefix
    # which is intended to exist only at the repostory name and shouldn't impact
    # the package naming... much...
    #
    # I didn't document this feature originally so it may not have been fully fleshed out...
    def load_template_configs
      template_config_path = File.join(@template_src, "bundlegem.yml")

      if File.exist?(template_config_path)
        t_config = YAML.load_file(template_config_path, symbolize_names: true)
      else
        t_config = {
          purpose: "tool",
          language: "go"
        }
      end

      if t_config[:prefix].nil?
        t_config[:prefix] = t_config[:purpose] ? "#{t_config[:purpose]}-" : ""
        t_config[:prefix] += t_config[:language] ? "#{t_config[:language]}-" : ""
      end

      t_config
    end

    # Returns a hash of source directory names and their destination mappings
    # This might not be needed???
    def dynamically_generate_template_directories
      template_dirs = Dir.glob("#{@template_src}/**/*", File::FNM_DOTMATCH).filter_map do |f|
        base_path = f[@template_src.length+1..-1]
        next if base_path.start_with?(".git" + File::SEPARATOR) || base_path == ".git"
        next if f == "#{@template_src}/." || f == "#{@template_src}/.."
        next unless File.directory?(f)
        # next if ignored_by_git?(@template_src, base_path)

        [base_path, substitute_template_values(base_path)]
      end.to_h
      filter_ignored_files!(@template_src, template_dirs)

      template_dirs
    end

    # Figures out the translation between all the .tt file to their
    # destination names
    def dynamically_generate_templates_files
      template_files = Dir.glob("#{@template_src}/**/*.tt", File::FNM_DOTMATCH).filter_map do |f|
        base_path = f[@template_src.length+1..-1]
        # next if ignored_by_git?(@template_src, base_path)

        [base_path, substitute_template_values(base_path).sub(/\.tt$/, "")]
      end.to_h

      raise_no_files_in_template_error! if template_files.empty?
      filter_ignored_files!(@template_src, template_files)

      return template_files
    end


    # Applies every possible substitution within config to the fs_obj_name
    def substitute_template_values(fs_obj_name)
      config.keys.inject(fs_obj_name) do |accu, key|
        if config[key].class == String
          accu.gsub(/\#\{#{key.to_s}\}/, config[key])
        else
          accu
        end
      end
    end

    def filter_ignored_files!(repo_root, path_hash)
      cmd = "git -C #{repo_root} check-ignore #{Shellwords.join(path_hash.keys)}"
      stdout, _, status = Open3.capture3(cmd)
      filter_these_paths = stdout.split

      path_hash.delete_if { |key, _| filter_these_paths.include?(key) }
    end

    def ignored_by_git?(repo_root, path)
      stdout, _, status = Open3.capture3("git -C #{repo_root} check-ignore #{Shellwords.escape(path)}")
      status.success? && !stdout.strip.empty?
    end

    def create_template_directories(template_directories, target)
      template_directories.each do |k,v|
        d = "#{target}/#{v}"
        puts " mkdir     #{d} ..."
        FileUtils.mkdir_p(d)
      end
    end

    # returns the full path of the template source
    def match_template_src
      template_src = ::Bundlegem::TemplateManager.get_template_src(@options)

      if File.exist?(template_src)
        return template_src    # 'newgem' refers to the built in template that comes with the gem
      else
        raise_template_not_found! # else message the user that the template could not be found
      end
    end

    def resolve_name(name)
      Pathname.pwd.join(name).basename.to_s
    end

    def validate_ext_name
      return unless gem_name.index('-')

      Bundler.ui.error "You have specified a gem name which does not conform to the \n" \
                       "naming guidelines for C extensions. For more information, \n" \
                       "see the 'Extension Naming' section at the following URL:\n" \
                       "http://guides.rubygems.org/gems-with-extensions/\n"
      exit 1
    end

    def bundler_dependency_version
      v = ::Gem::Version.new(Bundler::VERSION)
      req = v.segments[0..1]
      req << 'a' if v.prerelease?
      req.join(".")
    end


    #
    # EDIT:  Reworked from Thor to not rely on Thor (or do so much unneeded stuff)
    #
    # Gets an ERB template at the relative source, executes it and makes a copy
    # at the relative destination. If the destination is not given it's assumed
    # to be equal to the source removing .tt from the filename.
    #
    # ==== Parameters
    # source<String>:: the relative path to the source root.
    # destination<String>:: the relative path to the destination root.
    # config<Hash>:: give verbose:  false to not log the status.
    #
    # ==== Examples
    #
    #   template "README", "doc/README"
    #
    #   template "doc/README"
    #
    def template(source, *args, &block)
      config = args.last.is_a?(Hash) ? args.pop : {}
      destination = args.first || source.sub(/#{TEMPLATE_EXTNAME}$/, "")

      source  = File.expand_path(::Bundlegem::TemplateManager.find_in_source_paths(source.to_s))
      context = instance_eval("binding")

      make_file(destination, config) do
        content = ERB.new(::File.binread(source), trim_mode: "-", eoutvar: "@output_buffer").result(context)
        content = block.call(content) if block
        content
      end

      original_mode = File.stat(source).mode
      File.chmod(original_mode, destination)
    end

    def make_file(destination, config, &block)
      FileUtils.mkdir_p(File.dirname(destination))
      puts " Writing   #{destination} ..."
      File.open(destination, "wb") { |f| f.write block.call }
    end

    def raise_no_files_in_template_error!
      err_no_files_in_template = <<-HEREDOC
Ooops, the template was found for '#{@options[:template]}' in ~/.bundlegem/templates,
but no files within it ended in .tt.  Did you forget to rename the extensions of your files?

Exiting...
      HEREDOC
      puts err_no_files_in_template
      raise
    end

    def raise_project_with_that_name_already_exists!
      err_project_with_that_name_exists = <<-HEREDOC
Ooops, a project with the name #{target} already exists.
Can't make project.  Either delete that folder or choose a new project name

Exiting...
      HEREDOC
      puts err_project_with_that_name_exists
      raise
    end

    def raise_template_not_found!
      err_missing_template = "Could not find template folder '#{@options[:template]}' in `~/.bundle/templates/`. Please check to make sure your desired template exists."
      puts err_missing_template
      Bundler.ui.error err_missing_template
      raise
    end

    def time_it(label = nil)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed_ms = ((end_time - start_time) * 1000).round(2)
      puts "#{label || 'Elapsed'}: #{elapsed_ms} ms"
    end

    # This checks to see that the gem_name is a valid ruby gem name and will 'work'
    # and won't overlap with a bundlegem constant apparently...
    #
    # TODO:  This should be defined within the template itself in some way possibly, may have security implications
    def ensure_safe_gem_name(name, constant_array)
      if name =~ /^\d/
        Bundler.ui.error "Invalid gem name #{name} Please give a name which does not start with numbers."
        raise
      elsif Object.const_defined?(constant_array.first)
        Bundler.ui.error "Invalid gem name #{name} constant #{constant_array.join("::")} is already in use. Please choose another gem name."
        raise
      end
    end

  end
end
