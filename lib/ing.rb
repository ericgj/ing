['ing/lib_trollop',
 'ing/trollop/parser',
 'ing/util',
 'ing/dispatcher',
 'ing/shell',
 'ing/files',
 'ing/commands/boot',
 'ing/commands/implicit',
 'ing/commands/list',
 'ing/commands/generate'
].each do |f| 
  require_relative f
end

module Ing
  extend self
  
  attr_writer :shell_class

  def shell_class
    @shell_class ||= Shell::Basic
  end
      
  def implicit_booter
    ["Implicit"]
  end
  
  # Dispatch command line to boot class (if specified, or Boot otherwise), which 
  # dispatches the command after parsing args. 
  # Note boot dispatch happens within +Ing::Commands+ namespace.
  def run(argv=ARGV)
    booter = extract_boot_class!(argv) || implicit_booter
    run_boot booter, "call", *argv
  end
  
  # Dispatch to the command via +Ing::Boot#call_invoke+
  # Use this when you want to invoke a command from another command, but only
  # if it hasn't been run yet. For example,
  #
  #   invoke Some::Task, :some_instance_method, some_argument, :some_option => true
  #
  # Like running from the command line, you can skip the method and it will assume
  # +#call+ :
  #
  #   invoke Some::Task, :some_option => true
  def invoke(klass, *args)
    run_boot implicit_booter, "call_invoke", klass, *args
  end
  
  # Dispatch to the command via +Ing::Boot#call_execute+
  # Use this when you want to execute a command from another command, and you
  # don't care if it has been run yet or not. See equivalent examples under 
  # +invoke+.
  def execute(klass, *args)
    run_boot implicit_booter, "call_execute", klass, *args
  end
  
  private
  
  def run_boot(booter, *args)
    Dispatcher.new(["Ing","Commands"], booter, *args).dispatch
  end
  
  def extract_boot_class!(args)
    c = Util.to_class_names(args.first)
    if (Commands.const_defined?(c.first, false) rescue nil)
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
  
  
  Ing.run ["--debug", "--namespace=tests", "foo"]  # no method
  
  Ing.run ["--debug", "--namespace=tests", "--require=./tmp.rb", "--require=minitest/spec", "foo"]
  
  Ing.run ["--namespace=tests", "foo", "run", "--count=3"]   # method with args
    
  Ing.run ["--namespace=tests", "foo", "run", "boo"]   # method with non-option arg
  
  Ing.run ["--namespace=tests", "-d", "foo:bar", "--baz", "yes"]    # lambda with args
  
  # failures
  
#  Ing.run ["foo", "class"]    # illegal method
  
#  Ing.run ["baz"]             # class outside of namespace
  
  # tests of Ing.execute, Ing.invoke
  Ing::Dispatcher.dispatched.clear
  
  Ing.execute Tests::Foo, "run", :count => 1
  Ing.invoke Tests::Foo, "run", :count => 2
  Ing.execute Tests::Foo, "run", :count => 3
  
  puts "----->" + Ing::Dispatcher.dispatched.inspect
  
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
  
  
  Ing.run ["--namespace=tests", "zoo", "--verbose"]
  
  Ing.run ["generate", "--debug", "foo"]
  
end