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
        ns        = Ing::Util.to_class_names(options[:namespace] || 'object')
        cs        = Ing::Util.to_class_names(cmd)
        help = Dispatcher.new(ns, cs).help
        shell.say help.read
      end
      
    end
    
    H = Help
  
  end
end