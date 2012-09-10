# Base class

module Ing
  module Commands
    class Boot
    
      attr_accessor :options 
      attr_writer :shell
      
      def shell
        @shell ||= ::Ing.shell_class.new
      end
      
      def initialize(options)
        self.options = options
        debug "#{__FILE__}:#{__LINE__} :: options #{options.inspect}"
      end
      
      # Runs after options initialized but before any processing of arguments 
      # or dispatching the command.
      # Should be implemented in subclasses.
      def before(*args)
      end

      # Configure the command prior to dispatch.
      # Should be implemented in subclasses.
      # If you want to keep this default behavior setting the shell, 
      # call `super` first.
      def configure_command(cmd)
        cmd.shell = self.shell if cmd.respond_to?(:"shell=")
      end
      
      # Runs after dispatching the command.
      # Should be implemented in subclasses.
      def after
      end
      
      # Main processing of arguments and dispatch of the command
      def call(*args)
        before *args
        ns         = Ing::Util.to_class_names(options[:namespace] || 'object')
        classes    = Ing::Util.to_class_names(args.shift)
        meth, args = Ing::Util.split_method_args(args)      
        debug "#{__FILE__}:#{__LINE__} :: dispatch #{ns.inspect}, #{classes.inspect}, #{meth.inspect}, #{args.inspect}"
        Dispatcher.new(ns, classes, meth, *args).dispatch do |cmd|
          configure_command cmd
        end
        after
      end
      
      # Internal debugging -- define a :debug option in subclass if you want this
      def debug(*args)
        shell.debug(*args) if options[:debug]
      end

    end

  end
end