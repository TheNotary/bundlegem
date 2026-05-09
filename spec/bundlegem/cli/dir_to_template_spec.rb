require 'spec_helper'

module Bundlegem::CLI
  describe DirToTemplate do
    before :each do
      @mocked_home    = "/tmp/bundlegem_mock_home"
      @template_root  = "#{@mocked_home}/.bundlegem/templates"
      @dst_dir        = "/tmp/bundle_gem_dst_dir"
      @personal_repo  = "#{@template_root}/templates-Test" # name from reset_test_env

      reset_test_env
      FileUtils.cd(@dst_dir)
      @initial_dir = FileUtils.pwd
    end

    after :each do
      FileUtils.cd(@initial_dir)
    end

    def init_project(name, files: {})
      project_dir = "#{@dst_dir}/#{name}"
      FileUtils.mkdir_p(project_dir)
      FileUtils.cd(project_dir)
      files.each do |rel, contents|
        FileUtils.mkdir_p(File.dirname(rel)) unless File.dirname(rel) == "."
        File.write(rel, contents)
      end
      `git init -q && git add -A && git commit -q -m init`
      project_dir
    end

    it "errors when no personal templates repo exists" do
      init_project("cool-app", files: { "main.rb" => "puts 'hi'\n" })

      out = StringIO.new
      expect { DirToTemplate.go(output: out) }.to raise_error(Bundlegem::CLIError)
      expect(out.string).to include "Unable to convert to template, no personal templates repo exists."
      expect(out.string).to include "bundlegem --setup-personal-templates"
    end

    it "copies the project into the personal templates repo and runs the rename transform" do
      FileUtils.mkdir_p(@personal_repo)
      project_dir = init_project("cool-app", files: {
        "main.rb"          => "class CoolApp; end\nNAME = 'cool-app'\nMOD = 'cool_app'\nENV_VAR = 'COOL_APP_HOME'\n",
        ".gitignore"       => "ignored.log\n",
        "lib/cool_app.rb"  => "module CoolApp; end\n",
      })
      File.write("#{project_dir}/ignored.log", "should not be copied")

      out = StringIO.new
      DirToTemplate.go(output: out)

      dest = "#{@personal_repo}/cool-app"
      expect(File).to exist("#{dest}/main.rb")
      expect(File).to exist("#{dest}/lib/cool_app.rb")
      expect(File).to exist("#{dest}/.gitignore")
      expect(File).not_to exist("#{dest}/ignored.log")
      expect(File).not_to exist("#{dest}/.git")

      content = File.read("#{dest}/main.rb")
      expect(content).to include "FooBar"
      expect(content).to include "foo-bar"
      expect(content).to include "foo_bar"
      expect(content).to include "FOO_BAR"
      expect(content).not_to include "cool-app"
      expect(content).not_to include "CoolApp"

      expect(File.read("#{dest}/bundlegem.yml")).to include "category: misc"

      expect(out.string).to include "Template created at: #{dest}"
      expect(out.string).to match(/clean|review|remove/i)
    end

    it "preserves an existing bundlegem.yml in the source project" do
      FileUtils.mkdir_p(@personal_repo)
      init_project("cool-app", files: {
        "bundlegem.yml" => "category: backend\n",
        "main.rb"       => "puts 'hi'\n",
      })

      DirToTemplate.go(output: StringIO.new)

      dest = "#{@personal_repo}/cool-app"
      expect(File.read("#{dest}/bundlegem.yml")).to include "category: backend"
    end

    it "aborts if a template with the same basename already exists" do
      FileUtils.mkdir_p("#{@personal_repo}/cool-app")
      init_project("cool-app", files: { "main.rb" => "x" })

      out = StringIO.new
      expect { DirToTemplate.go(output: out) }.to raise_error(Bundlegem::CLIError)
      expect(out.string).to include "already exists at #{@personal_repo}/cool-app"
    end

    it "errors when not run inside a git repository" do
      FileUtils.mkdir_p(@personal_repo)
      project_dir = "#{@dst_dir}/no-git-app"
      FileUtils.mkdir_p(project_dir)
      FileUtils.cd(project_dir)

      out = StringIO.new
      expect { DirToTemplate.go(output: out) }.to raise_error(Bundlegem::CLIError)
      expect(out.string).to include "must be run from within a git repository"
    end
  end
end
