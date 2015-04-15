require "bundlegem/version"
require 'bundlegem/configurator'

module Bundlegem
  
  class << self
    
    # lists available templates
    def list
      configurator = Configurator.new
      # search through builtin
      available_templates = [ { "predefined" => "newgem" }, 
                              { "predefined" => "service" }]
      
      # search through user downloaded
      available_templates += configurator.user_downloaded_templates
      
      # search through user defined
      available_templates += configurator.user_defined_templates

      available_templates = group_hashes_by_key(available_templates)
      output_string = convert_grouped_hashes_to_output(available_templates)
      
      output_string
    end
    
    # input:  [ { "predefined" => "default" }, 
    #           { "MISC" => "my_thing" },
    #           { "prdefined" => "service" }
    #         ]
    #
    # output: [ { "predefined" => ["default", "service"] }, 
    #           { "MISC" => ["my_thing"] }
    #         ]     
    #
    def group_hashes_by_key(available_templates)
      h = {}
      available_templates.each do |hash|
        k = hash.first.first
        v = hash.first.last
        h[k] = [] unless h.has_key?(k)
        h[k] << v
      end
      h
    end
    
    # input:  [ { "predefined" => ["default", "service"] }, 
    #           { "MISC" => ["my_thing"] }
    #         ]  
    def convert_grouped_hashes_to_output(available_templates)
      s = ""
      available_templates.each do |hash|
        k = hash.first.upcase
        a = hash.last
        s << " #{k}:\n"
        a.each do |el|
          s << "   #{el}\n"
        end
        s << "\n"
      end
      s
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
