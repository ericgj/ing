require File.expand_path('gin/dispatcher', File.dirname(__FILE__))
require File.expand_path('gin/parser', File.dirname(__FILE__))
require File.expand_path('gin/generator', File.dirname(__FILE__))
require File.expand_path('gin/shell', File.dirname(__FILE__))

=begin 
# Usage: 


=end

module Gin
  
  class << self
    attr_writer :namespace, :shell_class, :generator_class, :parser_class
    def namespace
      @namespace ||= self
    end
    def shell_class
      @shell_class ||= Shell::Basic
    end
    def generator_class
      @generator_class ||= Generator
    end
    def parser_class
      @parser_class ||= Parser
    end
    
    def run(argv=ARGV)
      parse(argv).dispatch
    end
    
    def parse(argv=ARGV)
      Dispatcher.new(*parser_class.new(argv).parsed)
    end

    def dispatch(classes, meth=nil, args=[], opts={})
      Dispatcher.new(classes, meth, args, opts).dispatch
    end
  end
  
end

if $0 == __FILE__

  module Tests

    class Foo
      
      # this is what gets called if no args
      # in this case, the command-line options are passed into the generator
      def self.call(generator)
        foo = new
        foo.generator = generator
        foo.call
      end
      
      attr_accessor :generator
      
      def initialize(*args)
        @args = args
      end
      
      def call
        puts "called! with #{@args.inspect}, generator #{generator.inspect}"
      end
      
      def run(arg=nil)
        puts "run! with #{@args.inspect}, local arg #{arg.inspect}, generator #{generator.inspect}"
      end
      
      Bar = Proc.new {|g| puts "lambda called with generator #{g.inspect}"}
    end
    
  end

  Baz = Proc.new {|g| puts "lambda called with generator #{g.inspect}"}
  
  Gin.namespace = Tests
  
  Gin.run ["foo", "--verbose"]
  
  Gin.run ["foo", "run", "--pretend"]
    
  Gin.run ["foo", "run", "boo"]
  
  Gin.run ["foo:bar", "--force"]
  
  # failures
  
  Gin.run ["foo", "class"]
  
  Gin.run ["baz"]
  
end