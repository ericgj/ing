require 'fileutils'

require File.expand_path('actions/empty_directory', File.dirname(__FILE__))
require File.expand_path('actions/create_file', File.dirname(__FILE__))
require File.expand_path('actions/create_link', File.dirname(__FILE__))
require File.expand_path('actions/directory', File.dirname(__FILE__))
require File.expand_path('actions/file_manipulation', File.dirname(__FILE__))
require File.expand_path('actions/inject_into_file', File.dirname(__FILE__))


# Interface with base class:
#  - attr_reader :source_root, :destination_root
#  - attr_reader :shell, :options
#  - self.parse (optional; adds to it if defined)
module Gin
  module Files

    # a bit of trickiness to change a singleton method...
    def self.included(base)
      parse = base.method(:parse) if base.respond_to?(:parse)
      base.send(:define_singleton_method, :parse) do |expect|
        parse.call(expect) if parse
        expect.opt :verbose, "Run verbosely by default", :short => nil
        expect.opt :force, "Overwrite files that already exist", :short => nil
        expect.opt :pretend, "Run but do not make any changes", :short => nil
        expect.opt :revoke, "Revoke action", :short => nil
        expect.opt :quiet, "Suppress status output", :short => nil
        expect.opt :skip, "Skip files that already exist", :short => nil
      end
    end

    def pretend?
      !!options[:pretend]
    end
    
    def force?
      !!options[:force]
    end
    
    def verbose?
      !!options[:verbose]
    end
    
    def quiet?
      !!options[:quiet]
    end

    def revoke?
      !!options[:revoke]
    end
    
    def skip?
      !!options[:skip]
    end

    # Wraps an action object and call it accordingly to the behavior attribute.
    #
    def action(instance) #:nodoc:
      if revoke?
        instance.revoke!
      else
        instance.invoke!
      end
    end

    # Do something in the root or on a provided subfolder. If a relative path
    # is given it's referenced from the current root. The full path is yielded
    # to the block you provide. The path is set back to the previous path when
    # the method exits.
    #
    # ==== Parameters
    # dir<String>:: the directory to move to.
    # config<Hash>:: give :verbose => true to log and use padding.
    #
    def inside(dir='', config={}, &block)
      verbose = config.fetch(:verbose, verbose?)

      shell.say_status :inside, dir, verbose
      shell.padding += 1 if verbose
      destination_stack.push File.expand_path(dir, current_destination)

      # If the directory doesnt exist and we're not pretending
      if !File.exist?(current_destination)
        FileUtils.mkdir_p(current_destination, :noop => pretend?)
      end

      if pretend?
        # In pretend mode, just yield down to the block
        block.arity == 1 ? yield(current_destination) : yield
      else
        FileUtils.cd(current_destination) do
          block.arity == 1 ? yield(current_destination) : yield 
        end
      end
      
      destination_stack.pop
      shell.padding -= 1 if verbose
    end

    # Goes to the current root and execute the given block.
    #
    def in_root
      inside(current_destination) { yield }
    end
    
    private
    
    def destination_stack
      @_destination_stack ||= [destination_root]
    end
        
    def current_destination
      destination_stack.last
    end
    
  end
  
end

__END__
module Gin

  class Generator
    
    def self.from_source(root, opts={})
      g = new opts.delete(:shell), opts
      g.source_root = root
      g
    end
    
    def self.from_sources(paths, opts={})
      g = new opts.delete(:shell), opts
      g.source_paths += paths
      g
    end
    
    attr_accessor :shell
    
    def initialize(shell, opts={})
      self.shell = shell
      @options = opts
      @destination_stack = [Dir.pwd]
    end
    
    def behavior
      @options[:behavior]
    end
    
    def pretend?
      !!@options[:pretend]
    end
    
    def force?
      !!@options[:force]
    end
    
    def verbose?
      !!@options[:verbose]
    end
    
    def source_paths
      @_source_paths ||= []
    end

    # Stores and return the source root for this class
    def source_root(path=nil)
      @_source_root = path if path
      @_source_root
    end

    # Returns the source paths in the following order:
    #
    #   1) This class source paths
    #   2) Source root
    #
    def source_paths_for_search
      paths = []
      paths += self.source_paths
      paths << self.source_root if self.source_root
      paths
    end
    
    # Returns the current destination root
    #
    def destination_root
      @destination_stack.last
    end
    
    # Sets the destination root. Relatives path are added to the
    # directory where the script was invoked and expanded.
    #
    def destination_root=(root)
      @destination_stack.push File.expand_path(root || '')
    end
    
    
    # Wraps an action object and call it accordingly to the behavior attribute.
    #
    def action(instance) #:nodoc:
      if behavior == :revoke
        instance.revoke!
      else
        instance.invoke!
      end
    end
    
    # Receives a file or directory and search for it in the source paths.
    # TODO error handling in calling context
    #
    def find_in_source_paths(file)
      relative_root = destination_root

      source_paths.each do |source|
        source_file = File.expand_path(file, File.join(source, relative_root))
        return source_file if File.exists?(source_file)
      end

      message = "Could not find #{file.inspect} in any of your source paths. "

      unless self.class.source_root
        message << "Please invoke #{self.class.name}.source_root(PATH) with the PATH containing your templates. "
      end

      if source_paths.empty?
        message << "Currently you have no source paths."
      else
        message << "Your current source paths are: \n#{source_paths.join("\n")}"
      end

      raise Error, message
    end

    # Do something in the root or on a provided subfolder. If a relative path
    # is given it's referenced from the current root. The full path is yielded
    # to the block you provide. The path is set back to the previous path when
    # the method exits.
    #
    # ==== Parameters
    # dir<String>:: the directory to move to.
    # config<Hash>:: give :verbose => true to log and use padding.
    #
    def inside(dir='', config={}, &block)
      verbose = config.fetch(:verbose, false)

      shell.say_status :inside, dir, verbose
      shell.padding += 1 if verbose
      @destination_stack.push File.expand_path(dir, destination_root)

      # If the directory doesnt exist and we're not pretending
      if !File.exist?(destination_root) && !pretend?
        FileUtils.mkdir_p(destination_root)
      end

      if pretend?
        # In pretend mode, just yield down to the block
        block.arity == 1 ? yield(destination_root) : yield
      else
        FileUtils.cd(destination_root) { block.arity == 1 ? yield(destination_root) : yield }
      end

      @destination_stack.pop
      shell.padding -= 1 if verbose
    end

    # Goes to the root and execute the given block.
    #
    def in_root
      inside(destination_root) { yield }
    end

    # TODO are any of these needed?
    
    def apply(path, config={})
    end
    
    def run(command, config={})
    end
    
    def run_ruby_script(command, config={})
    end
    
    def thor(task, *args)
    end
    
  end

end