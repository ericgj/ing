
module Ing
  module Commands
  
    # This is the default boot command when ARGV.first not recognized as
    # a built-in Ing command. For example, `ing some:task run` .
    class Implicit < Boot
    
      DEFAULTS = {
         namespace: 'object',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.text "(internal)"
        parser.opt :debug, "Display debug messages"
        parser.opt :namespace, "Top-level namespace for generators",
                   :type => :string, :default => DEFAULTS[:namespace]
        parser.opt :require, "Require file or library before running (multi)", 
                   :multi => true, :type => :string
        parser.opt :ing_file, "Default generator file (ruby)", 
                   :type => :string, :short => 'f', 
                   :default => DEFAULTS[:ing_file]
        parser.stop_on_unknown
      end
      
      # Require each passed file or library before running
      # and require the ing file if it exists
      def before(*args)
        require_libs options[:require]
        require_ing_file
      end
      
      private
            
      # require relative paths relative to the Dir.pwd
      # otherwise, require as given (so gems can be required, etc.)
      def require_libs(libs)
        libs = Array(libs)
        libs.each do |lib| 
          f = if /\A\.{1,2}\// =~ lib
              File.expand_path(lib)
            else
              lib
            end
          debug "#{__FILE__}:#{__LINE__} :: require #{f.inspect}"
          require f
        end
      end

      def require_ing_file
        f = File.expand_path(options[:ing_file])
        require_libs(f) if File.exists?(f)
      end
      
    end

  end
end