require 'stringio'
      
module Ing

  class Dispatcher
    attr_accessor :dispatch_class, :dispatch_meth, :args, :options
    
    def initialize(namespaces, classes, meth, *args)
      ns                  = Util.namespaced_const_get(namespaces)
      self.dispatch_class = Util.namespaced_const_get(classes, ns)
      self.dispatch_meth  = valid_meth(meth, dispatch_class)
      self.args = args
    end
    
    def describe
      s=StringIO.new
      with_option_parser(self.dispatch_class) do |p|
        p.educate_banner s
      end
      s.rewind; s
    end
    
    def help
      s=StringIO.new
      with_option_parser(self.dispatch_class) do |p|
        p.educate s
      end
      s.rewind; s   
    end
    
    def dispatch
      self.options = parse_options!(args, dispatch_class)
      if dispatch_class.respond_to?(:new)
        cmd = dispatch_class.new(options)
        yield cmd if block_given?
        cmd.send(dispatch_meth, *args)
      else
        dispatch_class.call *args, options
      end
    end
        
    def with_option_parser(klass)
      return unless klass.respond_to?(:specify_options)
      klass.specify_options(p = Trollop::Parser.new)
      yield p
    end
    
    private
    
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