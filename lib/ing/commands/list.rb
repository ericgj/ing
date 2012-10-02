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
        parser.text "  ing list                # list all known commands that have a description"
        parser.text "  ing list -n rspec       # list all commands in rspec namespace"
        parser.text "  ing list rspec          # list commands that match /.*rspec/ (in any namespace)"
        parser.text "  ing list rspec --all    # list modules that don't have a description (not recommended!)"
        parser.text "  ing list -n rspec conv  # list commands that match /.*conv/ in rspec namespace"
        parser.text "\nOptions:"
        parser.opt :all, "List all tasks including modules that don't have a description", 
                   :default => false
        parser.opt :simple, "Simple list", :default => false
        parser.opt :strict, "List only tasks that are strictly within specified namespace", 
                   :default => false
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
        self.shell = shell_class.new
      end
      
      def call(s=nil)
        before
        if !options[:namespace_given]
          search_all s
        else
          search s
        end
      end
      
      def search(s, recurse=!options[:strict])
        _say_search(_namespace_class, %r|.*#{s}|, recurse)
      end
      
      def search_all(s, recurse=!options[:strict])
        _say_search(::Object, %r|.*#{s}|, recurse)
      end
      
      private 
      
      def _namespace_class(ns=options[:namespace])
        Util.decode_class(ns)
      end      
            
      def _say_search(mod, expr, recurse)
        commands = _search_results(mod, expr, recurse, self.options)
        if options[:simple]
          _say_commands commands
        else
          title = "All tasks #{options[:all] ? '' : 'with description'}"
          _say_commands_table commands, "#{mod}: #{title}"
        end
      end
      
      def _say_commands cmds
        $stdout.puts cmds.map(&:command_name)
      end
      
      def _say_commands_table(cmds, title)
        shell.say "-" * shell.dynamic_width
        shell.say title
        shell.say "-" * shell.dynamic_width
        shell.print_table cmds.map(&:command_line).zip(
                          cmds.map(&:desc_label))
      end
      
      def _search_results(mod, expr, recurse, opts={})
        _filtered_commands(mod, recurse, expr).map do |(cmd, klass)|
          c = CommandPresenter.new(Command.new(klass), cmd)
          next if !opts[:all] && !c.desc?
          c
        end.compact.sort {|a,b| a.command_line <=> b.command_line}
      end
            
      def _filtered_commands(mod, recurse, expr)
        Util.ing_commands(mod, recurse).select {|(cmd, klass)|
          expr =~ cmd
        }
      end
            
    end
   
    # alias
    L = List
    
    # internal class for presenting lists of commands
    class CommandPresenter
      attr_accessor :command, :command_name
      def initialize(cmd, name)
        self.command = cmd
        self.command_name = name
      end
      
      def help
        @help ||= command.help
      end
      
      def full_desc
        @full_desc ||= command.describe
      end

      def desc?
        !!full_desc
      end
      
      def desc
        (full_desc || '')[/.+$/]
      end
      
      def desc_label
        desc || '(no description)'
      end
      
      def command_line
        "ing #{command_name}"
      end
            
      def command_class
        command.command_class
      end
      
    end
    
  end
  
end