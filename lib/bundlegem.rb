require "bundlegem/version"




module Bundlegem
  # Your code goes here...
  
  class << self
    def which(executable)
      if File.file?(executable) && File.executable?(executable)
        executable
      elsif ENV['PATH']
        path = ENV['PATH'].split(File::PATH_SEPARATOR).find do |p|
          abs_path = File.join(p, executable)
          File.file?(abs_path) && File.executable?(abs_path)
        end
        path && File.expand_path(executable, path)
      end
    end
    
  end
  
end
