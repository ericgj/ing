module Ing

  # Use this module to define a default command to execute within a namespace.
  # Convenience methods for a typical case.
  #
  # @Example:
  #
  #    module Files
  #      extend Ing::DefaultCommand
  #      default_command :Export
  #
  #      class Export
  #        ...
  #      end
  #      class Import
  #        ...
  #      end
  #    
  #    end
  #    
  # Then from the command line this:
  #  
  #    ing files [ARGS]
  # 
  # is equivalent to
  #
  #    ing files:export [ARGS]
  #
  # and
  #
  #    ing list
  #
  # will display
  #
  #    ing files  # Default command: export
  #
  # PLEASE NOTE: extending your module with DefaultCommand will add state to 
  # your module: namely class instance variables @default_command and @shell,
  # and also a default +specify_options+ method (which will be overriden by
  # any you define on the underlying module).  
  #
  module DefaultCommand
  
    def default_command(name=nil)
      @default_command = name if name
      @default_command
    end
    
    attr_accessor :shell
  
    def specify_options(parser)
      parser.text \
        "Default command: #{Ing::Util.encode_class_names([default_command])}"
    end
    
    def call(*args)
      raise ArgumentError, 
            "No default command set for `#{self}`. Did you call `default_command :Default` ?" \
        unless self.default_command
      Ing.execute(self.const_get(default_command, false), *args) do |cmd|
        cmd.shell = self.shell if cmd.respond_to?(:"shell=")
      end
    end
  
  end

end
   