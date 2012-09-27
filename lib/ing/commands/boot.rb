module Ing

  # Base implementation of boot dispatch
  # Mixed in to Commands::Implicit, Commands::Generate
  # Note this does NOT provide any options, only provides implementation.
  # Assumes target class will provide +namespace+ option, otherwise defaults to
  # global namespace (::Object).
  #
  module Boot

    # Before hook passed unprocessed args, override in target class
    def before(*args)
    end
    
    # After hook, override in target class
    def after
    end
    
    # Configure the command prior to dispatch.
    # Override in target class
    def configure_command(cmd)
    end

    # Main processing of arguments and dispatch from command line (+Ing.run+)
    # Note that three hooks are provided for target classes, 
    #   +before+::  runs before any processing of arguments or dispatch of command
    #   +configure_command+::   configures the command prior to dispatch
    #   +after+::   runs after command dispatched
    #
    def call(*args)
      before *args
      klass         = _extract_class!(args)
      Ing.execute(klass, *args) do |cmd|
        configure_command cmd
      end
      after
    end    

    private
    
    def _extract_class!(args)
      Util.decode_class(args.shift, _namespace_class)
    end
    
    def _namespace_class
      return ::Object unless ns = options[:namespace]
      Util.decode_class(ns)
    end
    
  end
end