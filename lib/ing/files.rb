# Note: parts ripped directly out of Thor::Actions
#
# Copyright (c) 2008 Yehuda Katz, Eric Hodel, et al.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

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

        
    def current_destination
      destination_stack.last
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
    
    # Returns the given path relative to the absolute root (ie, root where
    # the script started).
    #
    def relative_to_original_destination_root(path, remove_dot=true)
      path = path.dup
      if path.gsub!(destination_root, '.')
        remove_dot ? (path[2..-1] || '') : path
      else
        path
      end
    end
    

    # Receives a file or directory and search for it in the source paths.
    #
    # Note that at minimum, the base object must define +source_root+.
    # If +source_paths+ is also defined, those will be used to search for files
    # first.
    #
    def find_in_source_paths(file)
      relative_root = relative_to_original_destination_root(current_destination, false)
      source_paths  = (respond_to?(:source_paths) ? self.source_paths : []) +
                      [self.source_root]
                      
      source_paths.each do |source|
        source_file = File.expand_path(file, File.join(source, relative_root))
        return source_file if File.exists?(source_file)
      end

      message = "Could not find #{file.inspect} in any of your source paths. "

      unless source_root
        message << "Please set the source_root with the path containing your templates."
      end

      if source_paths.empty?
        message << "Currently you have no source paths."
      else
        message << "Your current source paths are: \n#{source_paths.join("\n")}"
      end

      raise Ing::FileNotFoundError, message
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
      inside(destination_root) { yield }
    end
    
    private
    
    def destination_stack
      @_destination_stack ||= [destination_root]
    end
    
  end
  
end
