module Ing
  module Util
    extend self
    
    def to_class_names(str)
      str.split(':').map {|c| c.gsub(/(?:\A|_+)(\w)/) {$1.upcase} }
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