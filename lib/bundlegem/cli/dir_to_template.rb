require 'find'


module Bundlegem::Cli::DirToTemplate
  class << self

    def go
      validate_working_directory!
      file_enumerator = Find.find('.')

      Bundlegem::Core::DirToTemplate.🧙🪄! file_enumerator
    end

    private

    def validate_working_directory!
      # check for the existence of a .bundlegem file which won't ordinarily exist
      if !File.exist?(".bundlegem")
        raise "error: .bundlegem file not found in current directory.  Create it or run this command in the folder you thought you were in."
      end
    end

  end
end
