require 'pathname'
require 'yaml'
require 'open3'
require 'shellwords'
require 'set'

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
      @configurator = ::Bundlegem::Configurator.new

      @tconf = load_template_configs
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

      # Resolve domain values from ~/.bundlegem/config, prompting if needed
      required_domains = scan_template_for_required_domains
      prompt_for_missing_domains(required_domains)

      registry_domain = @configurator.domain('registry_domain')
      k8s_domain = @configurator.domain('k8s_domain')
      git_repo_domain = @configurator.domain('repo_domain') || 'github.com'

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

      image_path = "#{git_user_name}/#{name}".downcase
      registry_repo_path = "#{registry_domain}/#{image_path}".downcase

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
        :image_path       => image_path,
        :registry_domain  => registry_domain,
        :registry_repo_path => registry_repo_path,
        :k8s_domain       => k8s_domain,
        :template         => @options[:template],
        :test             => @options[:test],
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

    # Domain placeholder → config key mapping
    DOMAIN_PLACEHOLDERS = {
      'registry_domain' => %w[FOO_REGISTRY_DOMAIN FOO_REGISTRY_REPO_PATH],
      'k8s_domain'      => %w[FOO_K8S_DOMAIN],
      'repo_domain'     => %w[FOO_GIT_REPO_DOMAIN FOO_GIT_REPO_PATH FOO_GIT_REPO_URL],
    }.freeze

    # Human-readable names for prompting
    DOMAIN_DISPLAY_NAMES = {
      'registry_domain' => 'registry-domain',
      'k8s_domain'      => 'k8s-domain',
      'repo_domain'     => 'repo-domain',
    }.freeze

    DOMAIN_DEFAULTS = {
      'repo_domain' => 'github.com',
    }.freeze

    def scan_template_for_required_domains
      all_placeholders = DOMAIN_PLACEHOLDERS.values.flatten
      pattern = Regexp.union(all_placeholders)
      found_placeholders = Set.new

      Dir.glob("#{@template_src}/**/*", File::FNM_DOTMATCH).each do |f|
        next unless File.file?(f)
        base_path = f[@template_src.length+1..-1]
        next if base_path.nil?
        next if base_path.start_with?(".git" + File::SEPARATOR) || base_path == ".git"
        next if binary_file?(f)

        content = File.read(f)
        all_placeholders.each do |ph|
          found_placeholders << ph if content.include?(ph)
        end
      end

      # Map found placeholders back to domain config keys
      required = Set.new
      DOMAIN_PLACEHOLDERS.each do |domain_key, placeholders|
        required << domain_key if placeholders.any? { |ph| found_placeholders.include?(ph) }
      end
      required.to_a
    end

    def prompt_for_missing_domains(required_domains)
      required_domains.each do |domain_key|
        next if @configurator.domain(domain_key) && !@configurator.domain(domain_key).empty?

        display_name = DOMAIN_DISPLAY_NAMES[domain_key]
        default = DOMAIN_DEFAULTS[domain_key]
        default_hint = default ? " (default: #{default})" : ""

        puts "This template requires '#{display_name}'. The value will be saved to ~/.bundlegem/config for future use."
        print "Enter #{display_name}#{default_hint}: "
        value = $stdin.gets&.chomp || ''

        value = default if value.empty? && default

        if value.empty?
          puts "Warning: No value provided for '#{display_name}'. Template placeholders may not be fully resolved."
        end

        @configurator.set_domain(domain_key, value)
      end
    end

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

    # Figures out the translation between all template files and their
    # destination names
    def dynamically_generate_templates_files
      template_files = Dir.glob("#{@template_src}/**/*", File::FNM_DOTMATCH).filter_map do |f|
        base_path = f[@template_src.length+1..-1]
        next if base_path.nil?
        next if base_path.start_with?(".git" + File::SEPARATOR) || base_path == ".git"
        next if base_path == "bundlegem.yml"
        next unless File.file?(f)

        [base_path, substitute_template_values(base_path)]
      end.to_h

      raise_no_files_in_template_error! if template_files.empty?
      filter_ignored_files!(@template_src, template_files)

      return template_files
    end


    # Applies literal foo-bar variant substitutions to path strings
    def substitute_template_values(path_str)
      build_filename_replacement_pairs.inject(path_str) do |result, (find, replace)|
        result.gsub(find, replace)
      end
    end

    def build_filename_replacement_pairs
      [
        ['FOO_BAR',   config[:screamcase_name]],
        ['FooBar',    config[:pascal_name]],
        ['fooBar',    config[:camel_name]],
        ['foo-bar',   config[:name]],
        ['foo_bar',   config[:underscored_name]],
      ]
    end

    def build_content_replacement_pairs
      [
        # FOO_ prefixed non-name variables
        ['FOO_REGISTRY_REPO_PATH', config[:registry_repo_path]],
        ['FOO_GIT_REPO_DOMAIN',    config[:git_repo_domain]],
        ['FOO_GIT_REPO_PATH',      config[:git_repo_path]],
        ['FOO_GIT_REPO_URL',       config[:git_repo_url]],
        ['FOO_REGISTRY_DOMAIN',    config[:registry_domain]],
        ['FOO_IMAGE_PATH',         config[:image_path]],
        ['FOO_K8S_DOMAIN',         config[:k8s_domain]],
        ['FOO_AUTHOR',             config[:author]],
        ['FOO_EMAIL',              config[:email]],
        # Name-derived: compound/longer patterns first
        ['Foo::Bar',               config[:constant_name]],
        ['FOO_BAR',                config[:screamcase_name]],
        ['FooBar',                 config[:pascal_name]],
        ['fooBar',                 config[:camel_name]],
        ['Foo Bar',                config[:title]],
        ['foo/bar',                config[:namespaced_path]],
        ['foo-bar',                config[:name]],
        ['foo_bar',                config[:underscored_name]],
      ]
    end

    def binary_file?(path)
      chunk = File.binread(path, 8192)
      chunk.nil? || chunk.include?("\x00")
    end

    def filter_ignored_files!(repo_root, path_hash)
      cmd = "git -C #{repo_root} check-ignore #{Shellwords.join(path_hash.keys)}"
      stdout, _, status = Open3.capture3(cmd)
      filter_these_paths = stdout.split

      path_hash.delete_if { |key, _| filter_these_paths.include?(key) }
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



    # Reads a template source file, performs literal string replacements
    # of foo-bar variants and FOO_ prefixed placeholders, and writes
    # the result to the destination.
    def template(source, destination, _config = {})
      source = File.expand_path(source.to_s)

      if binary_file?(source)
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
      else
        content = File.read(source)
        content = content.gsub(/>>>\s+(\S+)/) { $1.chars.join("\x00") }
        build_content_replacement_pairs.each do |find, replace|
          content = content.gsub(find, replace)
        end
        content = content.gsub("\x00", '')
        make_file(destination, {}) { content }
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
but no files were found within it.

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
      err_missing_template = "Could not find template folder '#{@options[:template]}' in `~/.bundlegem/templates/`. Please check to make sure your desired template exists."
      $stderr.puts err_missing_template
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
    def ensure_safe_gem_name(name, constant_array)
      if name =~ /^\d/
        $stderr.puts "Invalid gem name #{name} Please give a name which does not start with numbers."
        raise
      end

      # TODO:  This validation should be defined within the template itself in some way
      # may have security implications
      if config[:template] == "ruby-cli-gem"
        if Object.const_defined?(constant_array.first)
          $stderr.puts "Invalid gem name #{name} constant #{constant_array.join("::")} is already in use. Please choose another gem name."
          raise
        end
      end
    end

  end
end
