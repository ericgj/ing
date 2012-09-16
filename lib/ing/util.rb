module Ing
  module Util
    extend self
    
    def to_class_names(str)
      str.split(':').map {|c| c.gsub(/(?:\A|_+)(\w)/) {$1.upcase} }
    end
    alias decode_class_names to_class_names
    
    def encode_class_names(list)
      list.map {|c| c.to_s.gsub(/([A-Z])/) {
          ($`.empty? ? "" : "_") + $1.downcase
        } 
      }.join(':')
    end
    
    def encode_class(klass)
      encode_class_names(klass.to_s.split('::'))
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
    
    # not used
    def split_method_args(args)
      if option?(args.first)
        [nil, args]
      else
        [args.first, args[1..-1]]
      end
    end    
    
    # Returns a string that has had any glob characters escaped.
    # The glob characters are `* ? { } [ ]`.
    #
    # ==== Examples
    #
    #   Util.escape_globs('[apps]')   # => '\[apps\]'
    #
    # ==== Parameters
    # String
    #
    # ==== Returns
    # String
    #
    def escape_globs(path)
      path.to_s.gsub(/[*?{}\[\]]/, '\\\\\\&')
    end
    
  end
  
end