require 'pathname'

module Bundler
  class CLI::Gem
    attr_reader :options, :gem_name, :thor, :name, :target

    def initialize(options, gem_name, thor)
      @options = options
      @gem_name = resolve_name(gem_name)
      @thor = thor

      @name = @gem_name
      @target = Pathname.pwd.join(gem_name)

      validate_ext_name if options[:ext]
    end

    def run
      Bundler.ui.confirm "Creating gem '#{name}'..."

      underscored_name = name.tr('-', '_')
      namespaced_path = name.tr('-', '/')
      constant_name = name.split('_').map{|p| p[0..0].upcase + p[1..-1] unless p.empty?}.join
      constant_name = constant_name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/
      constant_array = constant_name.split('::')
      git_user_name = `git config user.name`.chomp
      git_user_email = `git config user.email`.chomp

      config = {
        :name             => name,
        :underscored_name => underscored_name,
        :namespaced_path  => namespaced_path,
        :makefile_path    => "#{underscored_name}/#{underscored_name}",
        :constant_name    => constant_name,
        :constant_array   => constant_array,
        :author           => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
        :email            => git_user_email.empty? ? "TODO: Write your email address" : git_user_email,
        :template         => options[:template],
        :test             => options[:test],
        :ext              => options[:ext],
        :bin              => options[:bin],
        :bundler_version  => bundler_dependency_version
      }
      ensure_safe_gem_name(name, constant_array)

      # Hmmm... generate dynamically instead?
      templates = {
        "Gemfile.tt" => "Gemfile",
        "changelog.tt" => "changelog",
        "gitignore.tt" => ".gitignore",
        "lib/newgem.rb.tt" => "lib/#{namespaced_path}.rb",
        "lib/newgem/version.rb.tt" => "lib/#{namespaced_path}/version.rb",
        "newgem.gemspec.tt" => "#{name}.gemspec",
        "Rakefile.tt" => "Rakefile",
        "README.md.tt" => "README.md",
        "bin/console.tt" => "bin/console",
        "bin/setup.tt" => "bin/setup"
      }


      templates = dynamically_generate_templates || templates

      

      if ask_and_set(:coc, "Do you want to include a code of conduct in gems you generate?",
          "Codes of conduct can increase contributions to your project by contributors who " \
          "prefer collaborative, safe spaces. You can read more about the code of conduct at " \
          "contributor-covenant.org. Having a code of conduct means agreeing to the responsibility " \
          "of enforcing it, so be sure that you are prepared to do that. For suggestions about " \
          "how to enforce codes of conduct, see bit.ly/coc-enforcement."
        )
        templates.merge!("CODE_OF_CONDUCT.md.tt" => "CODE_OF_CONDUCT.md")
      end

      if ask_and_set(:mit, "Do you want to license your code permissively under the MIT license?",
          "This means that any other developer or company will be legally allowed to use your code " \
          "for free as long as they admit you created it. You can read more about the MIT license " \
          "at choosealicense.com/licenses/mit."
        )
        config[:mit] = true
        templates.merge!("LICENSE.txt.tt" => "LICENSE.txt")
      end

      if test_framework = ask_and_set_test_framework
        templates.merge!(".travis.yml.tt" => ".travis.yml")

        case test_framework
        when 'rspec'
          templates.merge!(
            "rspec.tt" => ".rspec",
            "spec/spec_helper.rb.tt" => "spec/spec_helper.rb",
            "spec/newgem_spec.rb.tt" => "spec/#{namespaced_path}_spec.rb"
          )
        when 'minitest'
          templates.merge!(
            "test/minitest_helper.rb.tt" => "test/minitest_helper.rb",
            "test/test_newgem.rb.tt" => "test/test_#{namespaced_path}.rb"
          )
        end
      end

      templates.merge!("exe/newgem.tt" => "exe/#{name}") if options[:bin]

      if options[:ext]
        templates.merge!(
          "ext/newgem/extconf.rb.tt" => "ext/#{name}/extconf.rb",
          "ext/newgem/newgem.h.tt" => "ext/#{name}/#{underscored_name}.h",
          "ext/newgem/newgem.c.tt" => "ext/#{name}/#{underscored_name}.c"
        )
      end


      template_src = match_template_src

      templates.each do |src, dst|
        thor.template("#{template_src}/#{src}", target.join(dst), config)
      end

      Bundler.ui.info "Initializing git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }

      if options[:edit]
        # Open gemspec in editor
        thor.run("#{options["edit"]} \"#{target.join("#{name}.gemspec")}\"")
      end
    end

    private

    def dynamically_generate_templates 
      return nil if options["template"].nil?

      template_src = get_template_src

      templates = {}
      Dir.glob("#{template_src}/**/*.tt").each do |f|
        base_path = f[template_src.length+1..-1]
        templates.merge!(base_path => base_path.gsub(/\.tt$/, "").gsub('#{name}', "#{name}") )
      end

      templates
    end

    def match_template_src
      template_src = get_template_src

      unless File.exists?(template_src)
        # else message the user that the template could not be found
        Bundler.ui.error "Could not find template folder #{options["template"]} in `~/.bundle/gem_templates/`. Please check to make sure your desired template exists."
        exit 1
      end

      template_src
    end

    def get_template_src
      if options["template"].nil?
        gem_template_location = ""
        gem_template = "newgem"
        template_src = "#{gem_template_location}#{gem_template}"
      else
        gem_template_location = File.expand_path("~/.bundle/gem_templates") +"/"
        gem_template = options["template"]
        template_src = "#{gem_template_location}#{gem_template}"
      end
    end

    def resolve_name(name)
      Pathname.pwd.join(name).basename.to_s
    end

    def ask_and_set(key, header, message)
      choice = options[key] || Bundler.settings["gem.#{key}"]

      if choice.nil?
        Bundler.ui.confirm header
        choice = (Bundler.ui.ask("#{message} y/(n):") =~ /y|yes/)
        Bundler.settings.set_global("gem.#{key}", choice)
      end

      choice
    end

    def validate_ext_name
      return unless gem_name.index('-')

      Bundler.ui.error "You have specified a gem name which does not conform to the \n" \
                       "naming guidelines for C extensions. For more information, \n" \
                       "see the 'Extension Naming' section at the following URL:\n" \
                       "http://guides.rubygems.org/gems-with-extensions/\n"
      exit 1
    end

    def ask_and_set_test_framework
      test_framework = options[:test] || Bundler.settings["gem.test"]

      if test_framework.nil?
        Bundler.ui.confirm "Do you want to generate tests with your gem?"
        result = Bundler.ui.ask "Type 'rspec' or 'minitest' to generate those test files now and " \
          "in the future. rspec/minitest/(none):"
        if result =~ /rspec|minitest/
          test_framework = result
        else
          test_framework = false
        end
      end

      if Bundler.settings["gem.test"].nil?
        Bundler.settings.set_global("gem.test", test_framework)
      end

      test_framework
    end

    def bundler_dependency_version
      v = Gem::Version.new(Bundler::VERSION)
      req = v.segments[0..1]
      req << 'a' if v.prerelease?
      req.join(".")
    end

    def ensure_safe_gem_name name, constant_array
      if name =~ /^\d/
        Bundler.ui.error "Invalid gem name #{name} Please give a name which does not start with numbers."
        exit 1
      elsif Object.const_defined?(constant_array.first)
        Bundler.ui.error "Invalid gem name #{name} constant #{constant_array.join("::")} is already in use. Please choose another gem name."
        exit 1
      end
    end

  end
end
