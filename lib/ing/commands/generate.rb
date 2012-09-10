# TODO extract a base class from this and Boot

module Ing
  module Commands
    class Generate

      DEFAULTS = {
         namespace: 'object',
         ing_file:  'ing.rb',
         gen_root:  ENV.fetch('ING_GENERATOR_ROOT', '~/.ing/generators')
      }
    
      def self.specify_options(parser)
        parser.opt :debug, "Display debug messages"
        parser.opt :namespace, "Top-level namespace for generators",
                   :type => :string, :default => DEFAULTS[:namespace]
        parser.opt :gen_root, "Generators root directory", 
                   :type => :string, :short => nil, 
                   :default => DEFAULTS[:gen_root]
        parser.opt :ing_file, "Default generator file (ruby)", 
                   :type => :string, :short => nil, 
                   :default => DEFAULTS[:ing_file]
        parser.stop_on_unknown
      end
     
      attr_accessor :options 
      attr_writer :shell
      
      def shell
        @shell ||= ::Ing.shell_class.new
      end
      
      def generator_root
        File.expand_path(options[:gen_root])
      end
      
      def initialize(options)
        self.options = options
        debug "#{__FILE__}:#{__LINE__} :: options #{options.inspect}"
      end
      
      # require based on args, then dispatch to the passed class/method
      # configuring it with a shell if possible
      def call(*args)
        require_generator args.first
        ns         = ::Ing::Util.to_class_names(options[:namespace])
        classes    = ::Ing::Util.to_class_names(args.shift)
        meth, args = ::Ing::Util.split_method_args(args)      
        debug "#{__FILE__}:#{__LINE__} :: dispatch #{classes.inspect}, #{meth.inspect}, #{args.inspect}"
        Dispatcher.new(ns, classes, meth, *args).dispatch do |cmd|
          cmd.shell = self.shell if cmd.respond_to?(:"shell=")
        end
      end

      # internal debugging
      def debug(*args)
        shell.debug(*args) if options[:debug]
      end
      
      private
          
      def require_generator(name)
        path = generator_name_to_path(name)
        require(
          if File.directory?(path)
            File.expand_path( File.join(path, options[:ing_file]), generator_root)
          else
            File.expand_path( File.join(path), generator_root )
          end
        )
      rescue LoadError
        raise LoadError, 
          "No generator found named `#{name}`. Check that you have set the generator root directory correctly (currently `#{generator_root}`)"
      end
      
      def generator_name_to_path(name)
        name.split(":").join("/")
      end
      
    end
    
    # alias
    G = Generate

  end
end