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
    end

    it 'is there' do
      create_user_defined_template(category: "wizardly_tools")
      files_changed = DirToTemplate.🧙🪄! Find.find('/tmp/temp/.'), dry_run: true

      expect(files_changed.first).to eq "Renamed: /tmp/temp/./README.md -> /tmp/temp/./README.md.tt"
    end
  end
end
