require 'spec_helper'

module Bundlegem
  describe TemplateManager do

    it '#get_template_src returns the template-test even if prefix is omitted' do
      options = { bin: false, ext: false, coc:  false, "template" => "test" }

      output = TemplateManager.get_template_src(options)

      expect(File.basename(output)).to eq "template-test"
    end

  end
end
