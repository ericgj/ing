
module Ing
  module Commands
  
    # This is the default boot command when ARGV.first not recognized as
    # a built-in Ing command. For example, `ing some:task run` .
    class Implicit < Boot
    
      def self.specify_options(parser)
        parser.opt :debug, "Display debug messages"
        parser.opt :namespace, "Top-level namespace for generators",
                   :type => :string, :default => 'object'
        parser.opt :require, "Require file or library before running (multi)", :multi => true, :type => :string
        parser.stop_on_unknown
      end
      
      # Require each passed file or library before running
      def before(*args)
        require_libs options[:require]
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

    end

  end
end