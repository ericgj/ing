require File.expand_path('ing/lib_trollop', File.dirname(__FILE__))
require File.expand_path('ing/dispatcher', File.dirname(__FILE__))
require File.expand_path('ing/shell', File.dirname(__FILE__))
require File.expand_path('ing/files', File.dirname(__FILE__))

module Ing
  
  class << self
    attr_writer :namespace, :shell_class
    def namespace
      @namespace ||= self
    end
    def shell_class
      @shell_class ||= Shell::Basic
    end
        
    # dispatch to boot:call, which dispatches the command after parsing args
    # resets globals afterwards
    def run(argv=ARGV)
      job = nil
      inside_namespace(self) do
        job = Dispatcher.new(["Boot"], "call", *argv)
      end
      job.dispatch
    end
        
    def inside_namespace(ns)
      saved_ns, self.namespace = namespace, ns
      yield
      self.namespace = saved_ns
    end
        
  end
  
  class Boot
  
    def self.specify_options(parser)
      parser.opt :debug, "Display debug messages"
      parser.opt :require, "Require file or library before running", :multi => true, :type => :string
#      parser.opt :verbose, "Run verbosely by default"
#      parser.opt :force, "Overwrite files that already exist"
#      parser.opt :pretend, "Run but do not make any changes"
#      parser.opt :quiet, "Suppress status output"
#      parser.opt :skip, "Skip files that already exist"
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

if $0 == __FILE__

  module Tests

    class Foo
      
      def self.call(*args)
        opts = (Hash === args.last ? args.pop : {})
        new(opts).call(*args)
      end
      
      def self.specify_options(p)
        p.opt :count, "Count", :type => :integer
      end
      
      attr_accessor :shell
      
      def initialize(opts={})
        @options = opts
      end
      
      def call(*args)
        shell.debug "called! with #{@options.inspect}, local args #{args.inspect}"
      end
      
      def run(*args)
        shell.debug "run! with #{@options.inspect}, local args #{args.inspect}"
      end
      
      Bar = Proc.new {|*opts| puts "lambda called with local options #{opts.inspect}"}
    end
    
  end

  Baz = Proc.new {|g| puts "lambda called with generator #{g.inspect}"}
  
  Ing.namespace = Tests
  
  Ing.run ["--debug", "foo"]  # no method
  
  Ing.run ["--debug", "--require=./tmp.rb", "--require=minitest/spec", "foo"]
  
  Ing.run ["foo", "run", "--count=3"]   # method with args
    
  Ing.run ["foo", "run", "boo"]   # method with non-option arg
  
  Ing.run ["-d", "foo:bar", "--baz", "yes"]    # lambda with args
  
  # failures
  
#  Ing.run ["foo", "class"]    # illegal method
  
#  Ing.run ["baz"]             # class outside of namespace
  
  # tests of Ing::Actions
  
  module Tests
  
    class Zoo
      
      def self.specify_options(expect)
        expect.opt :monkey, "Monkey test"
      end
      
      include Ing::Files
      attr_accessor :options, :destination_root, :source_root, :shell
      
      def initialize(options)
        self.options = options
        self.source_root = File.dirname(__FILE__)
        self.destination_root = File.expand_path('..',self.source_root)
        $stderr.puts "options :: #{self.options.inspect}"
      end
      
      def call(*args)
        in_root do
          inside "lib" do
          
          end
        end
      end
      
    end
    
  end
  
  
  Ing.run ["zoo", "--verbose"]
  
end