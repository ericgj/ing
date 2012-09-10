﻿require 'fileutils'

require File.expand_path('actions/empty_directory', File.dirname(__FILE__))
require File.expand_path('actions/create_file', File.dirname(__FILE__))
require File.expand_path('actions/create_link', File.dirname(__FILE__))
require File.expand_path('actions/directory', File.dirname(__FILE__))
require File.expand_path('actions/file_manipulation', File.dirname(__FILE__))
require File.expand_path('actions/inject_into_file', File.dirname(__FILE__))


# Interface with base class:
#  - attr_reader :source_root, :destination_root
#  - attr_reader :shell, :options
#  - self.specify_options (optional; adds to it if defined)
module Ing
  module Files

    # a bit of trickiness to change a singleton method...
    def self.included(base)
      meth = base.method(:specify_options) if base.respond_to?(:specify_options)
      base.send(:define_singleton_method, :specify_options) do |expect|
        meth.call(expect) if meth
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