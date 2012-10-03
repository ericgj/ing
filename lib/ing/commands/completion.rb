module Ing
  module Commands
  
    # Ing command used for auto-completion of ing commands
    # These are the general search cases:
    #
    # ing completion p        # print commands starting with p (recursively)
    # ing completion p:       # print commands in namespace p (recursively)
    # ing completion p:q      # print public methods in namespace p:q
    # ing completion p:q r    # print public methods in namespace p:q starting with r
    #
    class Completion

      DEFAULTS = List::DEFAULTS
      
      def self.specify_options(parser)
        parser.text "(for command auto-completion)"
        parser.stop_on_unknown
      end
      
      include Ing::CommonOptions
      
      attr_accessor :options
      def initialize(options)
        self.options = options
      end
      
      def before
        require_libs
        require_ing_file
      end
      
      def call(ns=nil,*args)
        before
        if k = (_namespace_class(ns) rescue nil)
          cmd = Ing::Command.new(k,*args)
          $stdout.puts _matching_methods_of(cmd)
        else
          Ing.execute List, :call, ns, options.merge({:simple => true})
        end
      end
      
      private
      
      # note kludge to force namespace vs method listing when input ends in ':'
      def _namespace_class(ns)
        return unless ns
        Ing::Util.decode_class(ns.gsub(/:$/,": "))
      end      
      
      def _matching_methods_of(cmd)
        cmd.instance
        expr = %r|^#{cmd.args.first}|
        (cmd.instance.public_methods - Object.public_methods).select {|m| 
          expr =~ m.to_s
        }.sort
      end
      
    end
  
  end
  
end