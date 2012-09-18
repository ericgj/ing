
module Ing

  # A base class to simplify typical task use-cases.
  # Adds some class methods and state to allow inherited options/flexibly-
  # ordered option specification.
  # Note that options are inherited to subclasses, but description and usage
  # lines are not.
  #
  class Task

    class << self
    
      attr_accessor :inherited_options
      
      def inherited(subclass)
        subclass.inherited_options = self.options.dup
      end
      
      def inherited_option?(name)
        inherited_options.has_key?(name)
      end
      
      def option?(name)
        options.has_key?(name)
      end
      
      # Modify the option named +name+ according to +specs+ (Hash).
      # Option will be created if it doesn't exist.
      #
      # Example:
      #
      #   modify_option :file, :required => true
      #
      def modify_option(name, specs)
        if inherited_option?(name)
          inherited_options[name].opts.merge!(specs)
        elsif option?(name)
          options[name].opts.merge!(specs)
        else
          opt(name, '', specs)
        end
      end
      
      # Modify the default for option +name+ to +val+.
      # Option will be created if it doesn't exist.
      def default(name, val)
        modify_option name, {:default => val}
      end
            
      # Add a description line
      def desc(line="")
        desc_lines << line
      end
      alias description desc
      
      # Add a usage line
      def usage(line="")
        usage_lines << line
      end
      
      # Add an option. Note the syntax is identical to +Trollop::Parser#opt+
      def opt(name, desc="", settings={})
        options[name] = Option.new(name, desc, settings)
      end
      alias option opt
      
      # Build option parser based on desc, usage, and options (including
      # inherited options). This method is called by `Ing::Dispatcher`.
      #
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
        unless inherited_options.empty?
          parser.text "\nCommon Options:"
          inherited_options.each do |name, opt|
            parser.opt *opt.to_args
          end
        end
      end
      
      # Description lines
      def desc_lines
        @desc_lines ||= []
      end
      
      # Usage lines
      def usage_lines
        @usage_lines ||= []
      end
      
      # Options hash. Note that in a subclass, options are copied down from 
      # superclass into inherited_options.
      def options
        @options ||= {}
      end
      
      protected
      
      def set_options(o)  #:nodoc:
        @options = o
      end
      
    end
    
    attr_accessor :options, :shell
    def initialize(options)
      self.options = initial_options(options)
    end
    
    # Override in subclass for adjusting given options on initialization
    def initial_options(given)
      given
    end

    # Build a hash of options that weren't given from command line via +ask+
    # (i.e., $stdin.gets).
    #
    # Note it currently does not cast options to appropriate types.
    # Also note because the shell is not available until after initialization,
    # this must be called from command method(s), e.g. +#call+
    #
    def ask_unless_given(*opts)
      opts.inject({}) do |memo, opt|
        next memo if options[:"#{opt}_given"]
        msg = self.class.options[opt].desc + "?"
        df  = self.class.options[opt].default
        memo[opt] = shell.ask(msg, :default => df)
        memo
      end
    end
    
    # Shortcut for:
    #
    #   options.merge! ask_unless_given :opt1, :opt2
    #
    def ask_unless_given!(*opts)
      self.options.merge! ask_unless_given(*opts)
    end
    
    # Use in initialization for option validation (post-parsing).
    #
    # Example:
    #
    #   validate_option(:color, "Color must be :black or :white") do |actual|
    #     [:black, :white].include?(actual)
    #   end
    #
    def validate_option(opt, desc=opt, msg=nil)
      msg ||= "Error in option #{desc} for `#{self.class}`."
      !!yield(self.options[opt]) or raise ArgumentError, msg
    end
    
    # Validate that the option was passed or otherwise defaulted to something truthy.
    # Note that in most cases, instead you should set :required => true on the option
    # and let Trollop catch the error -- rather than catching it post-parsing.
    #
    # Note +validate_option_exists+ will raise an error if the option is passed 
    # but false or nil, unlike the Trollop parser.
    #
    def validate_option_exists(opt, desc=opt)
      msg = "No #{desc} specified for #{self.class}. You must either " +
            "specify a `--#{opt}` option or set a default in #{self.class} or " +
            "in its superclass(es)."
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

