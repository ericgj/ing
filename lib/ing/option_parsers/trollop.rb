require 'stringio'
module Ing

  # Classes in this namespace provide a uniform interface to different
  # option parsers.
  #
  module OptionParsers
  
    class Trollop
      
      def parser
        @parser ||= ::Trollop::Parser.new
      end
      
      def parse!(args)
        ::Trollop.with_standard_exception_handling(parser) { parser.parse(args) }
      end
      
      def describe
        s=StringIO.new
        parser.educate_banner s
        s.rewind; s.to_s      
      end
      
      def help
        s=StringIO.new
        parser.educate s
        s.rewind; s.to_s      
      end
      
    end
    
  end
  
end