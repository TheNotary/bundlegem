require 'pathname'

module Bundlegem
  class CLI::Gem
    attr_reader :options, :gem_name, :name, :target

    def initialize(options, gem_name)
      @options = options
      @gem_name = resolve_name(gem_name)

      @name = @gem_name
      @target = Pathname.pwd.join(gem_name)

      validate_ext_name if options[:ext]
    end

    def run
      raise_project_with_that_name_already_exists! if File.exist?(target)

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
        :git_repo_url     => git_user_name.empty? ? "TODO: set your git username so link to repo is automatic" : "https://github.com/#{git_user_name}/#{underscored_name}",
        :template         => options[:template],
        :test             => options[:test],
        :ext              => options[:ext],
        :bin              => options[:bin],
        :bundler_version  => bundler_dependency_version
      }
      ensure_safe_gem_name(name, constant_array)

      template_src = match_template_src
      template_directories = dynamically_generate_template_directories
      templates = dynamically_generate_templates(config)

      puts "Creating new project folder '#{name}'\n\n"
      create_template_directories(template_directories, target)

      templates.each do |src, dst|
        template("#{template_src}/#{src}", target.join(dst), config)
      end


      # Bundler.ui.info "Initializing git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }

      # Disabled thanks to removal of thor, might not be helpful...
      #if options[:edit]
      #  # Open gemspec in editor
      #
      #  # thor.run("#{options["edit"]} \"#{target.join("#{name}.gemspec")}\"")
      #end

      puts "\nComplete."
    end

    private

    def dynamically_generate_template_directories
      # return nil if options["template"].nil?
      template_src = TemplateManager.get_template_src(options)

      template_dirs = {}
      Dir.glob("#{template_src}/**/*").each do |f|
        next unless File.directory? f
        base_path = f[template_src.length+1..-1]
        template_dirs.merge!(base_path => base_path.gsub('#{name}', "#{name}") )
      end
      template_dirs
    end

    # This function should be eliminated over time so that other methods conform to the
    # new algo for generating templates automatically.
    # Really, this function generates a template_src to template_dst naming
    # structure so that a later method can copy all the template files from the
    # source and rename them properly
    def generate_templates_for_built_in_gems(config)
      # Hmmm... generate dynamically instead?  Yes, overwritten below
      templates = {
        'Gemfile.tt' => "Gemfile",
        'changelog.tt' => "changelog",
        'gitignore.tt' => ".gitignore",
        'lib/#{name}.rb.tt' => "lib/#{config[:namespaced_path]}.rb",
        'lib/#{name}/version.rb.tt' => "lib/#{config[:namespaced_path]}/version.rb",
        '#{name}.gemspec.tt' => "#{config[:name]}.gemspec",
        'Rakefile.tt' => "Rakefile",
        'README.md.tt' => "README.md",
        'bin/console.tt' => "bin/console"
      }


      prompt_coc!(templates)
      prompt_mit!(templates, config)
      prompt_test_framework!(templates, config)

      templates.merge!("exe/newgem.tt" => "exe/#{config[:name]}") if config[:bin]

      if config[:ext]
        templates.merge!(
          "ext/newgem/extconf.rb.tt" => "ext/#{config[:name]}/extconf.rb",
          "ext/newgem/newgem.h.tt" => "ext/#{config[:name]}/#{config[:underscored_name]}.h",
          "ext/newgem/newgem.c.tt" => "ext/#{config[:name]}/#{config[:underscored_name]}.c"
        )
      end
      templates
    end

    # Figures out the translation between all the .tt file to their
    # destination names
    def dynamically_generate_templates(config)
      #if options["template"].nil? # if it's doing some of the built in template
      #  return generate_templates_for_built_in_gems(config)
      #else
        template_src = TemplateManager.get_template_src(options)

        templates = {}
        Dir.glob("#{template_src}/**/{*,.*}.tt").each do |f|
          base_path = f[template_src.length+1..-1]
          templates.merge!(base_path => base_path.gsub(/\.tt$/, "").gsub('#{name}', "#{name}") )
        end

        raise_no_files_in_template_error! if templates.empty?

        return templates
      #end
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
      template_src = TemplateManager.get_template_src(options)

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
      v = Gem::Version.new(Bundler::VERSION)
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
    # config<Hash>:: give :verbose => false to not log the status.
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

      source  = File.expand_path(TemplateManager.find_in_source_paths(source.to_s))
      context = instance_eval("binding")

      make_file(destination, config) do
        content = ERB.new(::File.binread(source), trim_mode: "-", eoutvar: "@output_buffer").result(context)
        content = block.call(content) if block
        content
      end

      original_mode = File.stat(source).mode
      File.chmod(original_mode, destination)
    end


    #
    # EDIT:  Reworked from Thor to not rely on Thor (or do so much unneeded stuff)
    #
    def make_file(destination, config, &block)
      FileUtils.mkdir_p(File.dirname(destination))
      puts " Writing   #{destination} ..."
      File.open(destination, "wb") { |f| f.write block.call }
    end



    def raise_no_files_in_template_error!
      err_no_files_in_template = <<-HEREDOC
Ooops, the template was found for '#{options['template']}' in ~/.bundlegem/templates,
but no files within it ended in .tt.  Did you forget to rename the extensions of your files?

Exiting...
      HEREDOC
      puts err_no_files_in_template
      exit
    end

    def raise_project_with_that_name_already_exists!
      err_project_with_that_name_exists = <<-HEREDOC
Ooops, a project with the name #{target} already exists.
Can't make project.  Either delete that folder or choose a new project name

Exiting...
      HEREDOC
      puts err_project_with_that_name_exists
      exit
    end

    def raise_template_not_found!
      err_missing_template = "Could not find template folder '#{options["template"]}' in `~/.bundle/templates/`. Please check to make sure your desired template exists."
      puts err_missing_template
      Bundler.ui.error err_missing_template
      exit 1
    end


    ############# STUFF THAT SHOULD BE REMOVED DOWN THE ROAD

    # This asks the user if they want to setup rspec or test...
    # It's not class based, it's additive based... Plus bundlegem does this already
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

    def ask_and_set(key, header, message)
      choice = options[key]  # || Bundler.settings["gem.#{key}"]

      if choice.nil?
        Bundler.ui.confirm header
        choice = (Bundler.ui.ask("#{message} y/(n):") =~ /y|yes/)
        Bundler.settings.set_global("gem.#{key}", choice)
      end

      choice
    end

    def prompt_coc!(templates)
      if ask_and_set(:coc, "Do you want to include a code of conduct in gems you generate?",
          "Codes of conduct can increase contributions to your project by contributors who " \
          "prefer collaborative, safe spaces. You can read more about the code of conduct at " \
          "contributor-covenant.org. Having a code of conduct means agreeing to the responsibility " \
          "of enforcing it, so be sure that you are prepared to do that. For suggestions about " \
          "how to enforce codes of conduct, see bit.ly/coc-enforcement."
        )
        templates.merge!("CODE_OF_CONDUCT.md.tt" => "CODE_OF_CONDUCT.md")
      end
    end

    def prompt_mit!(templates, config)
      if ask_and_set(:mit, "Do you want to license your code permissively under the MIT license?",
          "This means that any other developer or company will be legally allowed to use your code " \
          "for free as long as they admit you created it. You can read more about the MIT license " \
          "at choosealicense.com/licenses/mit."
        )
        config[:mit] = true
        templates.merge!("LICENSE.txt.tt" => "LICENSE.txt")
      end
    end

    def prompt_test_framework!(templates, config)
      namespaced_path = config[:namespaced_path]
      if test_framework = ask_and_set_test_framework
        templates.merge!(".travis.yml.tt" => ".travis.yml")

        case test_framework
        when 'rspec'
          templates.merge!(
            "rspec.tt" => ".rspec",
            "spec/spec_helper.rb.tt" => "spec/spec_helper.rb",
            'spec/#{name}_spec.rb.tt' => "spec/#{namespaced_path}_spec.rb"
          )
        when 'minitest'
          templates.merge!(
            "test/minitest_helper.rb.tt" => "test/minitest_helper.rb",
            "test/test_newgem.rb.tt" => "test/test_#{namespaced_path}.rb"
          )
        end
      end
    end

    # This checks to see that the gem_name is a valid ruby gem name and will 'work'
    # and won't overlap with a bundlegem constant apparently...
    #
    # TODO:  This should be defined within the template itself in some way possibly, may have security implications
    def ensure_safe_gem_name(name, constant_array)
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
