require 'spec_helper'
require 'find'

module Bundlegem::Core
  describe DirToTemplate do
    before :each do
      @mocked_home = "/tmp/bundlegem_mock_home"
      @template_root = "#{@mocked_home}/.bundlegem/templates"
      @dst_dir = "/tmp/bundle_gem_dst_dir"

      reset_test_env
      FileUtils.chdir(@dst_dir)
      @initial_dir = FileUtils.pwd
    end

    after :each do
      FileUtils.cd(@initial_dir)
    end

    it 'will process the expected files and ignore the ones that should be ignored' do
      template_dir = create_user_defined_template(category: "wizardly_tools")

      gitignored_file = "something.toignore"

      # Setup test template
      FileUtils.cd(template_dir)
      FileUtils.touch("#{template_dir}/README.md")
      FileUtils.touch("#{template_dir}/#{gitignored_file}")
      File.write("#{template_dir}/.gitignore", gitignored_file)
      `git init`

      files_changed = DirToTemplate.🧙🪄! Find.find("."), dry_run: true

      expect(files_changed[0]).to eq "Processed: ./README.md"
      expect(File).to exist "#{template_dir}/.gitignore"
      expect(files_changed.count).to eq 1
    end

    it 'conducts text replacements of package name variants' do
      template_dir = create_user_defined_template(category: "wizardly_tools")
      template_name = "cool-app"

      FileUtils.cd(template_dir)
      File.write("#{template_dir}/main.go", "package cool_app\nconst Name = \"cool-app\"\nconst ENV = \"COOL_APP_ENV\"\nclass CoolApp\n  def coolApp\n  end\nend\n")
      File.write("#{template_dir}/.gitignore", "")
      `git init`

      DirToTemplate.🧙🪄! Find.find("."), template_name: template_name

      content = File.read("#{template_dir}/main.go")
      expect(content).to include 'foo_bar'
      expect(content).to include 'foo-bar'
      expect(content).to include 'FOO_BAR'
      expect(content).to include 'FooBar'
      expect(content).to include 'fooBar'
      expect(content).not_to include 'cool-app'
      expect(content).not_to include 'cool_app'
      expect(content).not_to include 'COOL_APP'
      expect(content).not_to include 'CoolApp'
      expect(content).not_to include 'coolApp'
    end
  end
end
