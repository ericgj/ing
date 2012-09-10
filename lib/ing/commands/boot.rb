# This is the default boot command when ARGV.first not recognized as
# a built-in Ing command.

module Ing

  class Boot
  
    def self.specify_options(parser)
      parser.opt :debug, "Display debug messages"
      parser.opt :require, "Require file or library before running", :multi => true, :type => :string
      parser.stop_on_unknown
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
    
    # require libs, then dispatch to the passed class/method
    # configuring it with a shell if possible
    def call(*args)
      require_libs options[:require]
      classes = to_classes(args.shift)
      meth, args = split_method_args(args)      
      debug "#{__FILE__}:#{__LINE__} :: dispatch #{classes.inspect}, #{meth.inspect}, #{args.inspect}"
      Dispatcher.new(classes, meth, *args).dispatch do |cmd|
        cmd.shell = self.shell if cmd.respond_to?(:"shell=")
      end
    end
    
    # internal debugging
    def debug(*args)
      shell.debug(*args) if options[:debug]
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
        
    def to_classes(str)
      str.split(':').map {|c| c.gsub!(/(?:\A|_+)(\w)/) {$1.upcase} }
    end
    
    # args 'lookahead'; if next arg is an option, then method == nil
    # otherwise, use the next arg as the method
    def split_method_args(args)
      if /^-{1,2}/ =~ args.first
        [nil, args]
      else
        [args.first, args[1..-1]]
      end
    end
    
  end
  
end