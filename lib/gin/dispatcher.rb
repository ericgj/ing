module Gin

  class Dispatcher
    attr_accessor :dispatch_class, :dispatch_meth, :args, :options
    
    def initialize(classes, meth=nil, args=[], opts={})
      self.dispatch_class = get_const(classes, ::Gin.namespace)
      if meth
        self.dispatch_meth = whitelist(meth, dispatch_class) or 
                             raise NoMethodError, 
                              "undefined or insecure method `#{meth}` for #{dispatch_class}"
      end
      self.args = args
      self.options = opts
    end
    
    def dispatch
      if !dispatch_meth && args.empty?
        dispatch_class.call new_generator(options)
      else
        dispatch_class.new(options).send((dispatch_meth || :call), *args)
      end 
    end
    
    def new_shell
      ::Gin.shell_class.new
    end
    
    def new_generator(opts={})
      ::Gin.generator_class.new(new_shell, opts)
    end
    
    private
    
    def get_const(classes, base)
      classes.inject(base) {|memo, klass| memo.const_get(klass, false)}
    end
    
    def whitelist(meth, klass)
      klass.instance_methods(false).find {|m| m == meth.to_sym}
    end
    
  end
  
end