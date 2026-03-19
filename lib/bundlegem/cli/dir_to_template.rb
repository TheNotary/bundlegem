require 'find'


module Bundlegem::CLI
  module DirToTemplate
    class << self

      def go
        validate_working_directory!
        file_enumerator = Find.find('.')
        template_name = File.basename(Dir.pwd)

        Bundlegem::Core::DirToTemplate.🧙🪄! file_enumerator, template_name: template_name
      end

      private

      def validate_working_directory!
        # check for the existence of a bundlegem.yml file which won't ordinarily exist
        if !File.exist?("bundlegem.yml")
          puts "error: bundlegem.yml file not found in current directory.  Create it or run this command in the folder you thought you were in."
          exit 1
        end
      end

    end
  end
end
