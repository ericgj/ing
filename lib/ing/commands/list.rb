module Ing
  module Commands
    
    class List

      DEFAULTS = {
         namespace: 'ing:commands',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.banner "List all tasks within specified namespace"
        parser.text "\nUsage:"
        parser.text "  ing list        # list all built-in ing commands"
        parser.text "  ing list rspec  # list all ing commands in rspec namespace, or"
        parser.text "  ing list --namespace rspec"
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
      
      def call(ns=nil)
        before
        mod       = _namespace_class(ns)
        data = mod.constants.map do |c|
          klass = mod.const_get(c)
          desc = (Command.new(klass).describe || '')[/.+$/]
          [ "ing #{Ing::Util.encode_class(mod)}:#{Ing::Util.encode_class_names([c])}", 
            (desc || '(no description)').chomp
          ]
        end.sort
        shell.say desc_lines(mod, data).join("\n")
      end
      
      private 
      def _namespace_class(ns=options[:namespace])
        return ::Ing::Commands unless ns
        Util.decode_class(ns)
      end      
                  
      def desc_lines(mod, data)
        colwidths = data.inject([0,0]) {|max, (line, desc)| 
          max[0] = line.length if line.length > max[0]
          max[1] = desc.length if desc.length > max[1]
          max
        }
        ["#{mod}: all tasks",
         "-" * 80
        ] +
        data.map {|line, desc|
          [ line.ljust(colwidths[0]),
            desc[0...(80 - colwidths[0] - 3)]
          ].join(" # ")
        }
      end
      
    end
   
    L = List
  end
end