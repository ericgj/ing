module Ing
  module Util
    extend self
    
    def decode_class(str, base=::Object)
      namespaced_const_get( decode_class_names(str), base )
    end
    
    def decode_class_names(str)
      str.split(':').map {|c| c.gsub(/(?:\A|_+)(\w)/) {$1.upcase} }
    end    
    
    def encode_class(klass)
      encode_class_names(klass.to_s.split('::'))
    end
    
    def encode_class_names(list)
      list.map {|c| c.to_s.gsub(/([A-Z])/) {
          ($`.empty? ? "" : "_") + $1.downcase
        } 
      }.join(':')
    end
        
    def namespaced_const_get(list, base=::Object)
      list.inject(base) {|m, klass| m.const_get(klass, false)}
    end
    
    # search for {modules, callables} under base
    # note this does not pick up aliased constants right now
    def ing_commands(base, recurse=false, init={})
      base.constants(false).each do |c|
        next if base == Object && [:Config].include?(c)  # hack for deprecated ruby modules
        v = base.const_get(c)
        next if init.values.include?(v)
        if v.respond_to?(:constants)
          init[ encode_class(v) ] = v
          ing_commands(v,true,init) if recurse
        elsif v.respond_to?(:call)
          init[ encode_class_names(base.to_s.split('::') + [c]) ] = v
        end
      end
      init
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