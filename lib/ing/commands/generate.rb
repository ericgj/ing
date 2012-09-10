
module Ing
  module Commands
  
    # This is the boot command invoked from `ing generate ...`
    class Generate < Boot

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
                   :type => :string, :short => 'r', 
                   :default => DEFAULTS[:gen_root]
        parser.opt :ing_file, "Default generator file (ruby)", 
                   :type => :string, :short => 'f', 
                   :default => DEFAULTS[:ing_file]
        parser.stop_on_unknown
      end

      def generator_root
        @generator_root ||= File.expand_path(options[:gen_root])
      end
      
      # Locate and require the generator ruby file identified by the first arg,
      # before dispatching to it.
      def before(*args)
        require_generator args.first
      end
      
      private
          
      def require_generator(name)
        path = File.expand_path(generator_name_to_path(name), generator_root)
        f = if File.directory?(path)
          File.join(path, options[:ing_file])
        else
          path
        end
        debug "#{__FILE__}:#{__LINE__} :: require #{f.inspect}" 
        require f
      rescue LoadError
        raise LoadError, 
          "No generator found named `#{name}`. Check that you have set the generator root directory correctly (looking for `#{f}`)"
      end
      
      def generator_name_to_path(name)
        name.split(":").join("/")
      end
      
    end
    
    # alias
    G = Generate

  end
end