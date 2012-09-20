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
  
  class Command
  
    class << self
      attr_writer :parser
      def parser
        @parser ||= ::Ing::OptionParsers::Trollop.new  
      end
      
      def execute(klass, *args, &config)
        new(klass, *args).execute(&config)
      end
    end
    
    attr_accessor :options, :command_class, :command_meth, :args
    
    def initialize(klass, *args)
      self.options        = (Hash === args.last ? args.pop : {})
      self.command_class = klass
      self.command_meth  = extract_method!(args, command_class)
      self.args           = args
    end
    
    def classy?
      command_class.respond_to?(:new)
    end
    
    def instance
      @instance ||= build_command
    end
    
    def execute
      yield instance if block_given?
      classy? ? instance.send(command_meth, *args) : 
                instance.send(command_meth, *args, options)
    end

    def describe
      with_option_parser {|p| p.describe}
    end
    
    def help
      with_option_parser {|p| p.help}
    end
    
    def with_option_parser
      return {} unless command_class.respond_to?(:specify_options)
      p = self.class.parser
      command_class.specify_options(p.parser)
      yield p
    end
    
    private
    
    def build_command
      parse_options!
      classy? ? command_class.new(options) : command_class
    end
 
    # Note options merged into parsed options (reverse merge)
    # so that passed options (in direct invoke or execute) override defaults
    def parse_options!
      self.options = parsed_options_from_args.merge(self.options)
    end
    
    # memoized to avoid duplicate args processing
    def parsed_options_from_args
      @parsed_options ||= with_option_parser do |p|
                            p.parse! self.args
                          end
    end
        
    def extract_method!(args, klass)
      return :call if args.empty?
      if meth = whitelist(args.first, klass)
        args.shift
      else
        meth = :call
      end
      meth
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