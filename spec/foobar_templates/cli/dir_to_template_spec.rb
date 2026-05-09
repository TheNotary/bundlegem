require 'spec_helper'

module FoobarTemplates::CLI
  describe DirToTemplate do
    before :each do
      @mocked_home    = "/tmp/foobar_templates_mock_home"
      @template_root  = "#{@mocked_home}/.foobar/templates"
      @dst_dir        = "/tmp/foobar_templates_dst_dir"
      @personal_repo  = "#{@template_root}/templates-test" # name from reset_test_env

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
      expect { DirToTemplate.go(input: StringIO.new(""), output: out) }.to raise_error(FoobarTemplates::CLIError)
      expect(out.string).to include "Unable to convert to template, no personal templates repo exists."
      expect(out.string).to include "foobar_templates --setup-personal-templates"
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
      DirToTemplate.go(input: StringIO.new(""), output: out)

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

      expect(File.read("#{dest}/foobar.yml")).to include "category: misc"

      expect(out.string).to include "Template created at: #{dest}"
      expect(out.string).to match(/clean|review|remove/i)
    end

    it "preserves an existing foobar.yml in the source project" do
      FileUtils.mkdir_p(@personal_repo)
      init_project("cool-app", files: {
        "foobar.yml" => "category: backend\n",
        "main.rb"       => "puts 'hi'\n",
      })

      DirToTemplate.go(input: StringIO.new(""), output: StringIO.new)

      dest = "#{@personal_repo}/cool-app"
      expect(File.read("#{dest}/foobar.yml")).to include "category: backend"
    end

    it "prompts for a custom template folder name and category" do
      FileUtils.mkdir_p(@personal_repo)
      init_project("cool-app", files: {
        "main.rb"         => "class CoolApp; end\nNAME = 'cool-app'\n",
        "lib/cool_app.rb" => "module CoolApp; end\n",
      })

      out = StringIO.new
      DirToTemplate.go(input: StringIO.new("my-cool-template\nbackend\n"), output: out)

      dest = "#{@personal_repo}/my-cool-template"
      expect(File).to exist("#{dest}/main.rb")
      expect(File.read("#{dest}/foobar.yml")).to include "category: backend"

      content = File.read("#{dest}/main.rb")
      expect(content).to include "FooBar"
      expect(content).to include "foo-bar"
      expect(content).not_to include "cool-app"
      expect(content).not_to include "CoolApp"
    end

    it "defaults the category prompt to the existing foobar.yml category" do
      FileUtils.mkdir_p(@personal_repo)
      init_project("cool-app", files: {
        "foobar.yml" => "category: backend\n",
        "main.rb"       => "puts 'hi'\n",
      })

      out = StringIO.new
      DirToTemplate.go(input: StringIO.new("\n\n"), output: out)

      expect(out.string).to include "Category [backend]:"
      expect(File.read("#{@personal_repo}/cool-app/foobar.yml")).to include "category: backend"
    end

    it "rejects invalid template folder names" do
      FileUtils.mkdir_p(@personal_repo)
      init_project("cool-app", files: { "main.rb" => "x" })

      out = StringIO.new
      expect {
        DirToTemplate.go(input: StringIO.new("bad/name\n"), output: out)
      }.to raise_error(FoobarTemplates::CLIError)
      expect(out.string).to include "invalid template folder name"
    end

    it "aborts if a template with the same basename already exists" do
      FileUtils.mkdir_p("#{@personal_repo}/cool-app")
      init_project("cool-app", files: { "main.rb" => "x" })

      out = StringIO.new
      expect { DirToTemplate.go(input: StringIO.new(""), output: out) }.to raise_error(FoobarTemplates::CLIError)
      expect(out.string).to include "already exists at #{@personal_repo}/cool-app"
    end

    it "errors when not run inside a git repository" do
      FileUtils.mkdir_p(@personal_repo)
      project_dir = "#{@dst_dir}/no-git-app"
      FileUtils.mkdir_p(project_dir)
      FileUtils.cd(project_dir)

      out = StringIO.new
      expect { DirToTemplate.go(input: StringIO.new(""), output: out) }.to raise_error(FoobarTemplates::CLIError)
      expect(out.string).to include "must be run from within a git repository"
    end
  end
end
