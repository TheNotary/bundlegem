

module Bundlegem::CLI
  module CheatSheet
    class << self

      def go
        gem_root = File.expand_path("../../../..", __FILE__)
        File.read("#{gem_root}/spec/data/variable_manifest_test.rb").lines[3..-1].join
      end

    end
  end
end
