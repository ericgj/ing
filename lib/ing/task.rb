
module Ing

  # A base class to simplify typical task use-cases.
  # Adds some class methods and state to allow inherited options/flexibly-
  # ordered option specification.
  # Note that options are inherited to subclasses, but description and usage
  # lines are not.
  #
  class Task

    class << self
    
      def desc(line="")
        _options[:desc] << line
      end
      alias description desc
      
      def usage(line="")
        _options[:usage] << line
      end
      
      def opt(name, desc="", opts={})
        _options[:opt] << [name, desc, opts]
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
        unless (opts = options).empty?
          parser.text "\nOptions:"
          opts.each do |opt|
            parser.opt *opt
          end
        end
      end
      
      def desc_lines
        _options[:desc]
      end
      
      def usage_lines
        _options[:usage]
      end
      
      def options(inherit=true)
        return _options[:opt] if !inherit || !superclass.respond_to?(:options)
        superclass.options + _options[:opt]
      end
      
      private
      def _options
        @_options ||= Hash.new{|h,k|h[k]=[]}
      end
      
    end
    
    attr_accessor :options
    def initialize(options)
      self.options = initial_options(options)
    end
    
    # override in subclass for special behavior
    def initial_options(options)
      options
    end
    
  end
end

