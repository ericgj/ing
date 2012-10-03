module Ing

  # Common options for built-in Ing commands
  module CommonOptions
 
    # a bit of trickiness to change a singleton method...
    def self.included(base)
      meth = base.method(:specify_options) if base.respond_to?(:specify_options)
      base.send(:define_singleton_method, :specify_options) do |expect|
        meth.call(expect) if meth
        expect.text "\nCommon Options:"
        expect.opt :color, "Display output in color", :default => true
        expect.opt :debug, "Display debug messages"        
        expect.opt :namespace, "Top-level namespace",
                   :type => :string, :default => base::DEFAULTS[:namespace]
        expect.opt :require, "Require file or library before running (multi)", 
                   :multi => true, :type => :string
        expect.opt :ing_file, "Default task file (ruby)", 
                   :type => :string, :short => 'f', 
                   :default => base::DEFAULTS[:ing_file]
      end
    end
    
    def color?
      !!options[:color]
    end
    
    def debug?
      !!options[:debug]
    end
    
    def requires
      options[:require] || []
    end
    
    def ing_file
      options[:ing_file]
    end
    
    def namespace
      options[:namespace]
    end
    
    def shell_class
      color? ? Ing::Shell::Color : Ing::Shell::Basic
    end
    
    # require relative paths relative to the Dir.pwd
    # otherwise, require as given (so gems can be required, etc.)
    def require_libs(libs=requires)
      libs = Array(libs)
      libs.each do |lib| 
        f = if /\A\.{1,2}\// =~ lib
            File.expand_path(lib)
          else
            lib
          end
        require f
      end
    end

    def require_ing_file
      return unless ing_file
      f = File.expand_path(ing_file)
      require_libs(f) if f && File.exists?(f)
    end
    
    # Internal debugging
    def debug(*msgs)
      if debug?
        msgs.each do |msg| $stderr.puts "DEBUG :: #{msg}" end
      end
    end
    
  end
end