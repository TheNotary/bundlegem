require 'find'


module Bundlegem::CLI
  module DirToTemplate
    class << self

      # returns the list of templates currently available as a well formatted string
      def go
        validate_working_directory!
        file_enumerator = Find.find('.')

        output = Bundlegem::Core::DirToTemplate.🧙🪄! file_enumerator

        if output.empty?
          output = "You have no templates.  You can install the public example templates with\n"
          output += "the below command\n\n"
          output += "bundlegem --install-public-templates"
        end

        output
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
