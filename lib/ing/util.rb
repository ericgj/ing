module Ing
  module Util
    extend self
    
    def to_class_names(str)
      str.split(':').map {|c| c.gsub(/(?:\A|_+)(\w)/) {$1.upcase} }
    end
    
    def to_classes(str, base=::Object)
      namespaced_const_get( to_class_names(str), base )
    end
    
    def namespaced_const_get(list, base=::Object)
      list.inject(base) {|m, klass| m.const_get(klass, false)}
    end
    
    def option?(arg)
      !!(/^-{1,2}/ =~ arg)
    end
    
    def split_method_args(args)
      if option?(args.first)
        [nil, args]
      else
        [args.first, args[1..-1]]
      end
    end    
    
  end
  
end