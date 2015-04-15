require "bundlegem/version"
#require 'bundlegem/configurator'



module Bundlegem
  
  class << self
    
    # lists available templates
    def list
      binding.pry
      configurator = Configurator.new
      # search through builtin
      available_templates = ["default", "service"]
      
      # search through user downloaded
      # not implemented
      
      # search through user defined
      available_templates += configurator.user_defined_template_names
      
      return available_templates
    end
    
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
