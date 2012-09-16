module Ing
  module Commands
  
    class Help

      DEFAULTS = {
         namespace: 'ing:commands',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.text "Display help on specified command"
        parser.opt :debug, "Display debug messages"
        parser.opt :namespace, "Top-level namespace",
                   :type => :string, :default => DEFAULTS[:namespace]   
        parser.opt :require, "Require file or library before running (multi)", 
                   :multi => true, :type => :string
        parser.opt :ing_file, "Default task file (ruby)", 
                   :type => :string, :short => 'f', 
                   :default => DEFAULTS[:ing_file]
      end
      
      attr_accessor :options 
      attr_writer :shell
      
      def shell
        @shell ||= ::Ing.shell_class.new
      end
      
      def initialize(options)
        self.options = options
        debug "#{__FILE__}:#{__LINE__} :: options #{options.inspect}"
      end
      
      # Require each passed file or library before running
      # and require the ing file if it exists
      def before(*args)
        require_libs options[:require]
        require_ing_file
      end
    
      def call(cmd)
        before(cmd)
        ns        = Ing::Util.to_class_names(options[:namespace] || 'object')
        cs        = Ing::Util.to_class_names(cmd)
        help = Dispatcher.new(ns, cs).help
        shell.say help.read
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
            
      # Internal debugging
      def debug(*args)
        shell.debug(*args) if options[:debug]
      end
      
    end
    
    H = Help
  
  end
end