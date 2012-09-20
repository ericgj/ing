module Ing
  module Commands
  
    class Help

      DEFAULTS = {
         namespace: 'ing:commands',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.text "Display help on specified command"
        parser.text "\nUsage:"
        parser.text "  ing help generate               # help on built-in command generate"
        parser.text "  ing help --namespace test unit  # help on command within namespace"
        parser.text "  ing help                        # display this message"
      end
      
      include Ing::CommonOptions
      
      attr_accessor :options 
      attr_writer :shell
      
      def shell
        @shell ||= ::Ing.shell_class.new
      end
      
      def initialize(options)
        self.options = options
      end
      
      # Require each passed file or library before running
      # and require the ing file if it exists
      def before
        require_libs
        require_ing_file
      end
    
      def call(cmd="help")      
        before
        klass         = Util.decode_class(cmd, _namespace_class)
        help = Command.new(klass).help
        shell.say help
      end
      
      private
      def _namespace_class
        return ::Object unless ns = options[:namespace]
        Util.decode_class(ns)
      end      
      
    end
    
    H = Help
  
  end
end