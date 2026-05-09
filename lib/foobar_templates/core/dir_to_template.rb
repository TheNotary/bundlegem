require 'find'
require 'open3'
require 'shellwords'


module FoobarTemplates::Core::DirToTemplate
  class << self

    # Takes in a file_enumerator such as Find.find('.') and
    # performs literal string replacements of project name variants
    # with foo-bar template placeholders
    def 🧙🪄! file_enumerator, template_name: "asdf-pkg", dry_run: false
      # FOO_* composite values contain the project name (e.g. URLs, paths), so
      # they must be substituted BEFORE the name-variant replacements rewrite
      # `good-dog` → `foo-bar` inside them.
      replacements = build_foo_var_replacement_pairs(template_name) + build_replacement_pairs(template_name)
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

    # Reverse-substitute the user's real values for the FOO_* placeholders that
    # `FoobarTemplates::CLI::TemplateGenerator#build_interpolation_config` would have
    # interpolated. Keep this list in sync with that method.
    #
    # Ordered longest/most-specific first so composite values (URLs, paths)
    # are consumed before their substrings (bare domain, author).
    def build_foo_var_replacement_pairs(template_name)
      author = `git config user.name`.chomp
      email  = `git config user.email`.chomp

      configurator    = FoobarTemplates::Configurator.new
      repo_domain     = configurator.domain('repo_domain')
      registry_domain = configurator.domain('registry_domain')
      k8s_domain      = configurator.domain('k8s_domain')

      pairs = []

      if repo_domain && !repo_domain.empty? && author && !author.empty?
        git_repo_url  = "https://#{repo_domain}/#{author}/#{template_name}"
        git_repo_path = "#{repo_domain}/#{author}/#{template_name}".downcase
        pairs << [git_repo_url,  'FOO_GIT_REPO_URL']
        pairs << [git_repo_path, 'FOO_GIT_REPO_PATH']
      end

      if author && !author.empty?
        image_path = "#{author}/#{template_name}".downcase
        if registry_domain && !registry_domain.empty?
          registry_repo_path = "#{registry_domain}/#{image_path}".downcase
          pairs << [registry_repo_path, 'FOO_REGISTRY_REPO_PATH']
        end
        pairs << [image_path, 'FOO_IMAGE_PATH']
      end

      pairs << [registry_domain, 'FOO_REGISTRY_DOMAIN'] if registry_domain && !registry_domain.empty?
      pairs << [k8s_domain,      'FOO_K8S_DOMAIN']      if k8s_domain      && !k8s_domain.empty?
      pairs << [repo_domain,     'FOO_GIT_REPO_DOMAIN'] if repo_domain     && !repo_domain.empty?
      pairs << [email,           'FOO_EMAIL']           if email           && !email.empty?
      pairs << [author,          'FOO_AUTHOR']          if author          && !author.empty?

      pairs
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
        path == "./foobar.yml"        # skip the foobar.yml file
    end

    def ignored_by_git?(path)
      stdout, _, status = Open3.capture3("git check-ignore #{Shellwords.escape(path)}")
      return false unless status.exitstatus == 0 || status.exitstatus == 1
      status.success? && !stdout.strip.empty?
    end

  end
end
