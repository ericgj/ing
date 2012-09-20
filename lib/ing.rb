['ing/version',
 'ing/util',
 'ing/lib_trollop',
 'ing/trollop/parser',
 'ing/option_parsers/trollop',
 'ing/shell',
 'ing/common_options',
 'ing/files',
 'ing/task',
 'ing/generator',
 'ing/command',
 'ing/commands/boot',
 'ing/commands/implicit',
 'ing/commands/generate',
 'ing/commands/list',
 'ing/commands/help'
].each do |f| 
  require_relative f
end

module Ing
  extend self
  
  class << (Callstack = Object.new)
    
    def index(klass, meth)
      stack.index {|e| e == [klass,meth]}
    end
    
    def push(klass, meth)
      stack << [klass, meth]
    end
    
    def clear
      stack.clear
    end
    
    def to_a
      stack.dup
    end
    
    private
    def stack
      @stack ||= []
    end
    
  end
  
  def run(args=ARGV)
    booter = extract_boot_class!(args) || implicit_booter
    execute booter, *args
  end
  
  def execute(klass, meth=:call, opts={}, &config)
    Command.execute(klass, meth, opts, &config)
    Callstack.push(klass, meth.to_sym)
  end
  
  def invoke(klass, meth=:call, opts={}, &config)
    execute(klass, meth, opts, &config) unless executed?(klass, meth)
  end
  
  def executed?(klass, meth)
    !!Callstack.index(klass, meth)
  end
  
  def callstack
    Callstack.to_a
  end
  
  private
  
  def implicit_booter
    Ing::Commands::Implicit
  end
  
  def extract_boot_class!(args)
    c = Util.decode_class(args.first, Ing::Commands)
    args.shift; c
  rescue NameError
    nil
  end
  
end