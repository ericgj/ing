require 'stringio'
require 'set'
      
module Ing

  class Dispatcher
    
    # Global set of dispatched commands as [dispatch_class, dispatch_meth], 
    # updated before dispatch
    def self.dispatched
      @dispatched ||= Set.new
    end
    
    # +Ing.invoke+
    def self.invoke(klass, *args, &config)
      allocate.tap {|d| d.initialize_preloaded(true, klass, *args) }.
        dispatch(&config)
    end
    
    # +Ing.execute+
    def self.execute(klass, *args, &config)
      allocate.tap {|d| d.initialize_preloaded(false, klass, *args) }.
        dispatch(&config)
    end
        
    attr_accessor :dispatch_class, :dispatch_meth, :args, :options
    
    # True if current dispatch class/method has been dispatched before
    def dispatched?
      Dispatcher.dispatched.include?([dispatch_class,dispatch_meth])
    end
    
    # Default constructor from `Ing.run` (command line)
    def initialize(namespaces, classes, meth, *args)
      ns                  = Util.namespaced_const_get(namespaces)
      self.dispatch_class = Util.namespaced_const_get(classes, ns)
      self.dispatch_meth  = valid_meth(meth, dispatch_class)
      self.options        = parse_options!(args, dispatch_class)
      self.args           = args
      @invoking           = false
    end
    
    # Alternate constructor for preloaded object and arguments
    # i.e. from +invoke+ or +execute+ instead of +run+
    def initialize_preloaded(invoking, klass, *args)
      self.options        = (Hash === args.last ? args.pop : {})
      self.dispatch_class = klass
      self.dispatch_meth  = valid_meth(args.shift || :call, dispatch_class)
      self.args           = args
      @invoking           = invoking
    end
    
    # Returns stream (StringIO) of description text from specify_options.
    # Note this does not parse the options. Used by +Ing::Commands::List+.
    def describe
      s=StringIO.new
      with_option_parser(self.dispatch_class) do |p|
        p.educate_banner s
      end
      s.rewind; s
    end
    
    # Returns stream (StringIO) of help text from specify_options.
    # Note this does not parse the options. Used by +Ing::Commands::Help+.
    def help
      s=StringIO.new
      with_option_parser(self.dispatch_class) do |p|
        p.educate s
      end
      s.rewind; s   
    end
    
    # Public dispatch method used by all types of dispatch (run, invoke,
    # execute). Does not dispatch if invoking and already dispatched.
    def dispatch(&config)
      unless @invoking && dispatched?
        record_dispatch
        execute(&config)
      end
    end
    
    def with_option_parser(klass)   # :nodoc:
      return unless klass.respond_to?(:specify_options)
      klass.specify_options(p = Trollop::Parser.new)
      yield p
    end
    
    private
    
    def record_dispatch
      Dispatcher.dispatched.add [dispatch_class, dispatch_meth]
    end
    
    def execute
      if dispatch_class.respond_to?(:new)
        cmd = dispatch_class.new(options)
        yield cmd if block_given?
        cmd.send(dispatch_meth, *args)
      else
        dispatch_class.call *args, options
      end
    end
        
    def parse_options!(args, klass)
      with_option_parser(klass) do |p|
        Trollop.with_standard_exception_handling(p) { p.parse(args) }
      end
    end
    
    def valid_meth(meth, klass)
      meth ||= :call
      whitelist(meth, klass) or 
        raise NoMethodError, 
          "undefined or insecure method `#{meth}` for #{klass}"
    end
        
    # Note this currently does no filtering, but basically checks for respond_to
    def whitelist(meth, klass)
      finder = Proc.new {|m| m == meth.to_sym}
      if klass.respond_to?(:new)
        klass.public_instance_methods(true).find(&finder)
      else
        klass.public_methods.find(&finder)
      end
    end
    
  end
  
end