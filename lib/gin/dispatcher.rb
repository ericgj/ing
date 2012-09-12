# assumes  namespace:class method options
      
module Gin

  class Dispatcher
    attr_accessor :dispatch_class, :dispatch_meth, :args, :options
    
    def initialize(classes, meth, *args)
      self.dispatch_class = get_const(classes, ::Gin.namespace)
      self.dispatch_meth  = valid_meth(meth, dispatch_class)
      self.args = args
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
        
    private
    
    # class must be namespaced under base
    def get_const(classes, base)
      classes.inject(base) {|memo, klass| memo.const_get(klass, false)}
    end
    
    def parse_options!(args, klass)
      return {} unless klass.respond_to?(:parse)
      klass.parse(p = Trollop::Parser.new)
      Trollop.with_standard_exception_handling(p) { p.parse(args) }
    end
    
    def valid_meth(meth, klass)
      meth ||= :call
      whitelist(meth, klass) or 
        raise NoMethodError, 
          "undefined or insecure method `#{meth}` for #{klass}"
    end
    
    # method must be non-inherited instance method of klass
    def whitelist(meth, klass)
      finder = Proc.new {|m| m == meth.to_sym}
      if klass.respond_to?(:new)
        klass.instance_methods(false).find(&finder)
      else
        klass.methods.find(&finder)
      end
    end
    
  end
  
end