module Ing

  # Base implementation of boot dispatch
  # Mixed in to Commands::Implicit, Commands::Generate
  # Note this does NOT provide any options, only provides implementation.
  # Assumes target class will provide +namespace+ option, otherwise defaults to
  # global namespace (::Object).
  #
  module Boot

    # Configure the command prior to dispatch.
    # Default behavior is to set the shell of the dispatched command.
    # Override in target class as needed; if you want to keep the default 
    # behavior then call +super+.
    def configure_command(cmd)
      cmd.shell = Ing.shell_class.new if cmd.respond_to?(:"shell=")
    end
    
    # Main processing of arguments and dispatch from command line (+Ing.run+)
    # Note that three hooks are provided for target classes, 
    #   +before+::  runs before any processing of arguments or dispatch of command
    #   +configure_command+::   configures the command prior to dispatch
    #   +after+::   runs after command dispatched
    #
    def call(*args)
      before *args if respond_to?(:before)
      ns         = Ing::Util.to_class_names(options[:namespace] || 'object')
      classes    = Ing::Util.to_class_names(args.shift)
      Dispatcher.new(ns, classes, *args).dispatch do |cmd|
        configure_command cmd
      end
      after if respond_to?(:after)
    end    
    
    # Dispatch from +Ing.invoke+
    def call_invoke(klass, meth, *args)
      before *args if respond_to?(:before)
      Dispatcher.invoke(klass, meth, *args) do |cmd|
        configure_command cmd
      end
      after if respond_to?(:after)
    end
    
    # Dispatch from +Ing.execute+
    def call_execute(klass, meth, *args)
      before *args if respond_to?(:before)
      Dispatcher.execute(klass, meth, *args) do |cmd|
        configure_command cmd
      end
      after if respond_to?(:after)
    end
        
  end
end