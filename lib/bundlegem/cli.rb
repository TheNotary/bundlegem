require 'bundlegem'
require 'thor'

module Bundlegem
  class CLI < Thor
    include Thor::Actions
    AUTO_INSTALL_CMDS = %w[show binstubs outdated exec open console licenses clean]

    def self.start(*)
      super
    rescue Exception => e
      # Bundlegem.ui = UI::Shell.new
      puts e
      raise e
    ensure
      # Bundlegem.cleanup
    end

    def initialize(*args)
      super
      current_cmd = args.last[:current_command].name
      # custom_gemfile = options[:gemfile] || Bundlegem.settings[:gemfile]
      # ENV['BUNDLE_GEMFILE']   = File.expand_path(custom_gemfile) if custom_gemfile
      # Bundlegem::Retry.attempts = options[:retry] || Bundlegem.settings[:retry] || Bundlegem::Retry::DEFAULT_ATTEMPTS
      # Bundlegem.rubygems.ui = UI::RGProxy.new(Bundlegem.ui)
      # auto_install if AUTO_INSTALL_CMDS.include?(current_cmd)
    rescue UnknownArgumentError => e
      raise InvalidOption, e.message
    ensure
      self.options ||= {}
      # Bundlegem.ui = UI::Shell.new(options)
      # Bundlegem.ui.level = "debug" if options["verbose"]
    end

    check_unknown_options!(:except => [:config, :exec])
    stop_on_unknown_option! :exec

    default_task :gem
    class_option "no-color", :type => :boolean, :desc => "Disable colorization in output"
    class_option "retry",    :type => :numeric, :aliases => "-r", :banner => "NUM",
      :desc => "Specify the number of times you wish to attempt network commands"
    class_option "verbose",  :type => :boolean, :desc => "Enable verbose output mode", :aliases => "-V"

    def help(cli = nil)
      case cli
      when "gemfile" then command = "gemfile.5"
      when nil       then command = "bundle"
      else command = "bundle-#{cli}"
      end

      manpages = %w(
          bundle
          bundle-config
          bundle-exec
          bundle-install
          bundle-package
          bundle-update
          bundle-platform
          gemfile.5)

      if manpages.include?(command)
        root = File.expand_path("../man", __FILE__)

        if Bundlegem.which("man") && root !~ %r{^file:/.+!/META-INF/jruby.home/.+}
          Kernel.exec "man #{root}/#{command}"
        else
          puts File.read("#{root}/#{command}.txt")
        end
      else
        super
      end
    end

    def self.handle_no_command_error(command, has_namespace = $thor_runner)
      require 'bundlegem/cli/gem'
      Gem.new(options, name, self).run



      # return super unless command_path = Bundlegem.which("Bundlegem-#{command}")

      # Kernel.exec(command_path, *ARGV[1..-1])
    end

    desc "init [OPTIONS]", "Generates a Gemfile into the current working directory"
    long_desc <<-D
      Init generates a default Gemfile in the current working directory. When adding a
      Gemfile to a gem with a gemspec, the --gemspec option will automatically add each
      dependency listed in the gemspec file to the newly created Gemfile.
    D
    method_option "gemspec", :type => :string, :banner => "Use the specified .gemspec to create the Gemfile"
    def init
      require 'bundlegem/cli/init'
      Init.new(options.dup).run
    end



    desc "version", "Prints the bundler's version information"
    def version
      Bundler.ui.info "Bundler version #{Bundler::VERSION}"
    end
    map %w(-v --version) => :version


    desc "gem GEM [OPTIONS]", "Creates a skeleton for creating a rubygem"
    method_option :bin, :type => :boolean, :default => false, :aliases => '-b', :desc => "Generate a binary for your library. Set a default with `bundle config gem.mit true`."
    method_option :coc, :type => :boolean, :desc => "Generate a code of conduct file. Set a default with `bundle config gem.coc true`."
    method_option :edit, :type => :string, :aliases => "-e", :required => false, :banner => "EDITOR",
      :lazy_default => [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find{|e| !e.nil? && !e.empty? },
      :desc => "Open generated gemspec in the specified editor (defaults to $EDITOR or $BUNDLER_EDITOR)"
    method_option :ext, :type => :boolean, :default => false, :desc => "Generate the boilerplate for C extension code"
    method_option :mit, :type => :boolean, :desc => "Generate an MIT license file"
    method_option :test, :type => :string, :lazy_default => 'rspec', :aliases => '-t', :banner => "rspec",
      :desc => "Generate a test directory for your library, either rspec or minitest. Set a default with `bundle config gem.test rspec`."
    method_option :template, :type => :string, :lazy_default => "cli_gem", :aliases => '-u', :banner => "default", :desc => "Generate a gem based on the user's predefined template."
    def gem(name)
      # options = {bin: false, ext: false}
      # name = "gem_name"
      # self.class == Bundlegem::CLI
      require 'bundlegem/cli/gem'
      Gem.new(options, name, self).run
    end

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    end


    desc "platform [OPTIONS]", "Displays platform compatibility information"
    method_option "ruby", :type => :boolean, :default => false, :banner =>
      "only display ruby related platform information"
    def platform
      require 'bundlegem/cli/platform'
      Platform.new(options).run
    end


    desc "env", "Print information about the environment Bundler is running under"
    def env
      Env.new.write($stdout)
    end

    private

      # Automatically invoke `bundle install` and resume if
      # Bundler.settings[:auto_install] exists. This is set through config cmd
      # `bundle config auto_install 1`.
      #
      # Note that this method `nil`s out the global Definition object, so it
      # should be called first, before you instantiate anything like an
      # `Installer` that'll keep a reference to the old one instead.
      def auto_install
        return unless Bundler.settings[:auto_install]

        begin
          Bundler.definition.specs
        rescue GemNotFound
          Bundler.ui.info "Automatically installing missing gems."
          Bundler.reset!
          invoke :install, []
          Bundler.reset!
        end
      end
  end
end
