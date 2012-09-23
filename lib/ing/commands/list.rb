module Ing
  module Commands
    
    class List

      DEFAULTS = {
         namespace: 'ing:commands',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.banner "List all tasks by name or in specified namespace"
        parser.text "\nUsage:"
        parser.text "  ing list                # list all built-in ing commands"
        parser.text "  ing list -n rspec       # list all commands in rspec namespace"
        parser.text "  ing list rspec          # search for commands that match /.*rspec/ (in any namespace)"
        parser.text "  ing list rspec --all    # include modules that don't have a description in list (not recommended)"
        parser.text "  ing list -n rspec conv  # search for commands that match /.*conv/ in rspec namespace"
        parser.text "\nOptions:"
        parser.opt :all, "List all tasks including modules that don't have a description", :default => false
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
      
      def call(s=nil)
        before
        if !options[:namespace_given]
          search_all s
        else
          search s
        end
      end
      
      def search(s)
        _do_search(_namespace_class, %r|.*#{s}|, false)
      end
      
      def search_all(s)
        _do_search(::Object, %r|.*#{s}|, true)
      end
      
      private 
      
      def _namespace_class(ns=options[:namespace])
        Util.decode_class(ns)
      end      
            
      def _do_search(mod, expr, recurse)
        data = filtered_commands(mod, recurse, expr).map do |(cmd, klass)|
          desc = (Command.new(klass).describe || '')[/.+$/]
          cmd_and_description(cmd, desc) if options[:all] || desc 
        end.compact.sort
        title = "All tasks #{options[:all] ? '' : 'with description'}"
        shell.say desc_lines(mod, data, title).join("\n")
      end
      
      def filtered_commands(mod, recurse, expr)
        Util.ing_commands(mod, recurse).select {|(cmd, klass)|
          expr =~ cmd
        }
      end
      
      def cmd_and_description(cmd, desc)
        [ "ing #{cmd}", 
          (desc || '(no description)').chomp
        ]      
      end
      
      def desc_lines(mod, data, title="all tasks")
        colwidths = data.inject([0,0]) {|max, (line, desc)| 
          max[0] = line.length if line.length > max[0]
          max[1] = desc.length if desc.length > max[1]
          max
        }
        ["#{mod}: #{title}",
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