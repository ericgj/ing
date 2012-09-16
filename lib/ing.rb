['ing/lib_trollop',
 'ing/trollop/parser',
 'ing/util',
 'ing/dispatcher',
 'ing/shell',
 'ing/files',
 'ing/commands/boot',
 'ing/commands/implicit',
 'ing/commands/list',
 'ing/commands/help',
 'ing/commands/generate'
].each do |f| 
  require_relative f
end

module Ing
  extend self
  
  Error = Class.new(StandardError)
  FileNotFoundError = Class.new(Error)
  
  attr_writer :shell_class

  def shell_class
    @shell_class ||= Shell::Basic
  end
      
  def implicit_booter
    ["Implicit"]
  end
  
  # Dispatch command line to boot class (if specified, or Implicit otherwise), 
  # which in turn dispatches the command after parsing args. 
  #
  # Note boot dispatch happens within +Ing::Commands+ namespace.
  #
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
  # You can skip the method and it will assume +#call+ :
  #
  #   invoke Some::Task, :some_option => true
  def invoke(klass, *args)
    run_boot implicit_booter, "call_invoke", klass, *args
  end
  
  # Dispatch to the command via +Ing::Boot#call_execute+
  # Use this when you want to execute a command from another command, and you
  # don't care if it has been run yet or not. See equivalent examples for 
  # +invoke+.
  #
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
  
  # tests of Ing.execute, Ing.invoke
  Ing::Dispatcher.dispatched.clear
  
  Ing.execute Tests::Foo, "run", :count => 1
  Ing.invoke Tests::Foo, "run", :count => 2
  Ing.execute Tests::Foo, "run", :count => 3
  
  puts "----->" + Ing::Dispatcher.dispatched.inspect
  
end