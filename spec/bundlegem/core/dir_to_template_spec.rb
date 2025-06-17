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

    it 'will rename the expected files and ignore the ones that should be ignored' do
      template_dir = create_user_defined_template(category: "wizardly_tools")

      gitignored_file = "something.toignore"

      # Setup test template
      FileUtils.cd(template_dir)
      FileUtils.touch("#{template_dir}/README.md")
      FileUtils.touch("#{template_dir}/#{gitignored_file}")
      File.write("#{template_dir}/.gitignore", gitignored_file)
      `git init`

      files_changed = DirToTemplate.🧙🪄! Find.find("."), dry_run: true

      expect(files_changed[0]).to eq "Renamed: ./.gitignore -> ./.gitignore.tt"
      expect(files_changed[1]).to eq "Renamed: ./README.md -> ./README.md.tt"
      expect(File).to exist "#{template_dir}/.gitignore"
      expect(files_changed.count).to eq 2
    end
  end
end
