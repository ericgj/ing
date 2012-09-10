['ing/lib_trollop',
 'ing/util',
 'ing/dispatcher',
 'ing/shell',
 'ing/files',
 'ing/commands/boot',
 'ing/commands/generate'
].each do |f| 
  require File.expand_path(f, File.dirname(__FILE__)) 
end

module Ing
  extend self
  
  attr_writer :namespace, :shell_class
  def namespace
    @namespace ||= self::Commands
  end
  def shell_class
    @shell_class ||= Shell::Basic
  end
      
  # dispatch to boot class (if specified, or Boot otherwise), which 
  # dispatches the command after parsing args. 
  # Note boot dispatch happens within Ing::Commands namespace.
  def run(argv=ARGV)
    job = nil
    inside_boot_namespace do
      booter = extract_boot_class!(argv) || ["Boot"]
      job = Dispatcher.new(booter, "call", *argv)
    end
    job.dispatch
  end
      
  def inside_boot_namespace(&b)
    inside_namespace(self::Commands, &b)
  end
  
  def inside_namespace(ns)
    saved_ns, self.namespace = namespace, ns
    yield
    self.namespace = saved_ns
  end
  
  private
  
  def extract_boot_class!(args)
    c = Util.to_class_names(args.first)
    if (self.namespace.const_defined?(c.first) rescue nil)
      args.shift; c
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