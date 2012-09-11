require File.expand_path('gin/lib_trollop', File.dirname(__FILE__))
require File.expand_path('gin/dispatcher', File.dirname(__FILE__))
require File.expand_path('gin/shell', File.dirname(__FILE__))
require File.expand_path('gin/generator', File.dirname(__FILE__))

module Gin
  
  class << self
    attr_writer :namespace, :shell_class, :options
    def namespace
      @namespace ||= self
    end
    def shell_class
      @shell_class ||= Shell::Basic
    end
    def options
      @options ||= {}
    end
        
    # dispatch to boot:call, dispatch, then reset globals
    def run(argv=ARGV)
      reset_after do
        job = nil
        inside_namespace(self) do
          job = Dispatcher.new(["Boot"], "call", *argv)
        end
        job.dispatch
      end
    end
    
    def reset_after
      ns, sh, op = self.namespace, self.shell_class, self.options
      yield
      self.namespace, self.shell_class, self.options = ns, sh, op      
    end
    
    def inside_namespace(ns)
      saved_ns, self.namespace = namespace, ns
      yield
      self.namespace = saved_ns
    end
    
    # internal debugging
    def debug(*args)
      return unless options[:debug]
      args = ([""] + args) if args.length == 1
      $stderr.puts [args[0].ljust(20), args[1]].join(' : ')
    end
    
  end
  
  class Boot
  
    def self.parse(parser)
      parser.opt :debug, "Display debug messages"
      parser.opt :verbose, "Run verbosely by default"
      parser.opt :force, "Overwrite files that already exist"
      parser.opt :pretend, "Run but do not make any changes"
      parser.opt :quiet, "Suppress status output"
      parser.opt :skip, "Skip files that already exist"
      parser.stop_on_unknown
    end

    def initialize(options)
      ::Gin.options = options
    end
    
    # dispatch to the passed class/method
    def call(*args)
      classes = to_classes(args.shift)
      meth, args = split_method_args(args)
      Dispatcher.new(classes, meth, *args).dispatch
    end
        
    private
    
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
      
      def self.parse(p)
        p.opt :count, "Count", :type => :integer
      end
      
      def initialize(opts={})
        @options = opts
      end
      
      def call(*args)
        puts "called! with #{@options.inspect}, local args #{args.inspect}"
      end
      
      def run(*args)
        puts "run! with #{@options.inspect}, local args #{args.inspect}"
      end
      
      Bar = Proc.new {|*opts| puts "lambda called with local options #{opts.inspect}"}
    end
    
  end

  Baz = Proc.new {|g| puts "lambda called with generator #{g.inspect}"}
  
  Gin.namespace = Tests
  
  Gin.run ["--verbose", "--debug", "foo"]  # no method
  
  Gin.run ["--pretend", "foo", "run", "--count=3"]   # method with args
    
  Gin.run ["foo", "run", "boo"]   # method with non-option arg
  
  Gin.run ["-q", "foo:bar", "--baz", "yes"]    # lambda with args
  
  # failures
  
#  Gin.run ["foo", "class"]    # illegal method
  
#  Gin.run ["baz"]             # class outside of namespace
  
end