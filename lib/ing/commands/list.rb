module Ing
  module Commands
    
    class List

      DEFAULTS = {
         namespace: 'ing:commands',
         ing_file:  'ing.rb'
      }
      
      def self.specify_options(parser)
        parser.text "List all tasks within specified namespace"
        parser.opt :debug, "Display debug messages"
        parser.opt :namespace, "Top-level namespace for generators",
                   :type => :string, :default => DEFAULTS[:namespace]   
        parser.opt :require, "Require file or library before running (multi)", 
                   :multi => true, :type => :string
        parser.opt :ing_file, "Default generator file (ruby)", 
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

      
      def call(*args)
        before(*args)
        ns        = Ing::Util.to_class_names(options[:namespace] || 'object')
        mod       = Ing::Util.namespaced_const_get(ns)
        data = mod.constants.map do |c|
          desc = Dispatcher.new(ns, [c], nil, []).describe
          [ "ing #{Ing::Util.encode_class_names(ns + [c])}", 
            (desc.gets || '(no description)').chomp
          ]
        end.sort
        shell.say desc_lines(ns, data).join("\n")
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
      
      def desc_lines(ns, data)
        colwidths = data.inject([0,0]) {|max, (line, desc)| 
          max[0] = line.length if line.length > max[0]
          max[1] = desc.length if desc.length > max[1]
          max
        }
        ["#{ns.join(' ')}: all tasks",
         "-" * 80
        ] +
        data.map {|line, desc|
          [ line.ljust(colwidths[0]),
            desc[0...(80 - colwidths[0] - 2)]
          ].join("  ")
        }
      end

      # Internal debugging
      def debug(*args)
        shell.debug(*args) if options[:debug]
      end
      
    end
    
  end
end