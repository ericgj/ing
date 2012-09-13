module Ing
  module Commands
    
    class List

      def self.specify_options(parser)
        parser.text "List all tasks within specified namespace"
        parser.opt :debug, "Display debug messages"
        parser.opt :namespace, "Top-level namespace for generators",
                   :type => :string, :default => 'ing:commands'        
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

      def call(*args)
        ns        = Ing::Util.to_class_names(options[:namespace] || 'object')
        mod       = Ing::Util.namespaced_const_get(ns)
        data = mod.constants.map do |c|
          desc = Dispatcher.new(ns, [c], nil, []).describe
          [ "ing #{Ing::Util.encode_class_names([c])}", 
            (desc.gets || '(no description)').chomp
          ]
        end.sort
        shell.say desc_lines(ns, data).join("\n")
      end
      
      private 
      
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