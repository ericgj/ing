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
        parser.text "  ing help generate               # help on built-in command 'generate'"
        parser.text "  ing help unit --namespace test  # help on command 'unit' within namespace 'test'"
        parser.text "  ing help --namespace test:unit  # another syntax"
        parser.text "  ing help test:unit              # yet another syntax"
        parser.text "  ing help                        # display this message"
      end
      
      include Ing::CommonOptions
      
      attr_accessor :options, :shell
      
      def initialize(options)
        self.options = options
      end
      
      # Require each passed file or library before running
      # and require the ing file if it exists
      def before
        require_libs
        require_ing_file
        self.shell = shell_class.new; self.shell.base = self
      end
    
      def call(cmd=nil)      
        before
        if options[:namespace_given]
          if cmd
            _do_help cmd, _namespace_class
          else
            _do_help _namespace_class
          end
        else
          if cmd
            if /:/ =~ cmd
              _do_help cmd
            else
              _do_help cmd, _namespace_class
            end
          else
            _do_help 'help', _namespace_class
          end
        end
      end
      
      private
      
      def _do_help(cmd, ns=::Object)
        klass = Util.decode_class(cmd, ns)
        help = Command.new(klass).help
        shell.say help
      end
      
      def _namespace_class(ns=options[:namespace])
        Util.decode_class(ns)
      end      
      
    end
    
    H = Help
  
  end
end