
module Ing
  module Commands
  
    # This is the default boot command when ARGV.first not recognized as
    # a built-in Ing command. For example, `ing some:task run` .
    class Implicit
    
      DEFAULTS = {
         namespace: 'object',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.text "(internal)"
        parser.stop_on_unknown
      end
      
      include Ing::Boot
      include Ing::CommonOptions
      
      attr_accessor :options
      def initialize(options)
        self.options = options
      end
         
      # Require each passed file or library before running
      # and require the ing file if it exists
      def before(*args)
        require_libs
        require_ing_file
      end
      
      def configure_command(cmd)
        cmd.shell = shell_class.new if cmd.respond_to?(:"shell=")
      end
      
    end

  end
end