
module Ing

  # A base class to simplify typical task use-cases.
  # Adds some class methods and state to allow inherited options/flexibly-
  # ordered option specification.
  # Note that options are inherited to subclasses, but description and usage
  # lines are not.
  #
  class Task

    class << self
    
      def inherited(subclass)
        subclass.set_options self.options.dup
      end
      
      def modify_option(name, specs)
        opt(name) unless options[name]
        options[name].opts.merge!(specs)
      end
      
      def default(name, val)
        #options[name].default = val
        modify_option name, {:default => val}
      end
            
      def desc(line="")
        desc_lines << line
      end
      alias description desc
      
      def usage(line="")
        usage_lines << line
      end
      
      def opt(name, desc="", settings={})
        options[name] = Option.new(name, desc, settings)
      end
      alias option opt
      
      def specify_options(parser)
        desc_lines.each do |line|
          parser.text line
        end
        unless usage_lines.empty?
          parser.text "\nUsage:"
          usage_lines.each do |line|
            parser.text line
          end
        end
        unless options.empty?
          parser.text "\nOptions:"
          options.each do |name, opt|
            parser.opt *opt.to_args
          end
        end
      end
      
      def desc_lines
        @desc_lines ||= []
      end
      
      def usage_lines
        @usage_lines ||= []
      end
      
      def options
        @options ||= {}
      end
      
      protected
      
      def set_options(o)
        @options = o
      end
      
    end
    
    attr_accessor :options, :shell
    def initialize(options)
      self.options = initial_options(options)
    end
    
    # override in subclass for special behavior
    def initial_options(options)
      options
    end

    def validate_option(opt, desc=opt, msg=nil)
      msg ||= "Error in option #{desc} for `#{self.class}`."
      !!yield(self.options[opt]) or
        raise ArgumentError, msg
    end
    
    def validate_option_exists(opt, desc=opt)
      msg = "No #{desc} specified for #{self.class}. You must either " +
            "specify a `--#{opt}` option or set a default in #{self.class}."
      validate_option(opt, desc, msg) {|val| val }
    end
    
  end
  
  class Option < Struct.new(:name, :desc, :opts)
    
    def initialize(*args)
      super
      self.opts ||= {}
    end
    
    def default; opts[:default]; end
    def default=(val)
      opts[:default] = val
    end
    
    def type; opts[:type]; end
    def type=(val)
      opts[:type] = val
    end
    
    def multi; opts[:multi]; end
    def multi=(val)
      opts[:multi] = val
    end
    
    def long; opts[:long]; end
    def long=(val)
      opts[:long] = val
    end    
    
    def short; opts[:short]; end
    def short=(val)
      opts[:short] = val
    end
    
    def to_args
      [name, desc, opts]
    end
    
  end
  
end

