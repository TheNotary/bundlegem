require 'spec_helper'

module FoobarTemplates
  describe TemplateManager do

    before :each do
      @template_root = "#{ENV['HOME']}/.foobar/templates"
      FileUtils.rm_rf(ENV['HOME'])
      FileUtils.mkdir_p(@template_root)
    end

    def write_template_config(path, config_contents)
      FileUtils.mkdir_p(path)
      File.write("#{path}/foobar.yml", config_contents)
    end

    it '#get_template_src returns the template-test even if prefix is omitted' do
      options = { bin: false, ext: false, coc:  false, template: "test" }

      output = TemplateManager.get_template_src(options)

      expect(File.basename(output)).to eq "template-test"
    end

    it 'resolves a unique leaf template inside monorepo templates' do
      write_template_config("#{@template_root}/template-platform", "monorepo: true\n")
      write_template_config("#{@template_root}/template-platform/template-api", "category: services\n")

      options = { bin: false, ext: false, coc: false, template: "api" }
      output = TemplateManager.get_template_src(options)

      expect(output).to end_with("template-platform/template-api")
    end

    it 'raises an ambiguity error for duplicate monorepo leaf names' do
      write_template_config("#{@template_root}/template-platform-a", "monorepo: true\n")
      write_template_config("#{@template_root}/template-platform-a/template-api", "category: services\n")
      write_template_config("#{@template_root}/template-platform-b", "monorepo: true\n")
      write_template_config("#{@template_root}/template-platform-b/template-api", "category: services\n")

      options = { bin: false, ext: false, coc: false, template: "api" }

      expect do
        TemplateManager.get_template_src(options)
      end.to raise_error(FoobarTemplates::CLIError, /Ambiguous template name 'api'/)
    end

    it 'raises a not-found error when monorepo leaf template does not exist' do
      write_template_config("#{@template_root}/template-platform", "monorepo: true\n")
      write_template_config("#{@template_root}/template-platform/template-api", "category: services\n")

      options = { bin: false, ext: false, coc: false, template: "does-not-exist" }

      expect do
        TemplateManager.get_template_src(options)
      end.to raise_error(FoobarTemplates::CLIError, /not found in monorepo leaf templates/)
    end

    it 'raises a CLIError when the template path does not exist' do
      options = { bin: false, ext: false, coc: false, template: "does-not-exist" }

      expect do
        TemplateManager.get_template_src(options)
      end.to raise_error(FoobarTemplates::CLIError, /could not be found/)
    end

  end
end
