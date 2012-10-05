require 'pathname'

module Ing
  module Commands
  
    class Gemify

      EXECUTABLE_TEMPLATE = <<_____
#!/usr/bin/env ruby
require 'ing'
<% gem_files_from_bindir.each do |r| %>
require File.expand_path('<%= r %>', File.dirname(__FILE__))
<% end %> 
Ing.execute <%= command.command_class %>, :<%= command.command_meth %>, *ARGV
_____

      GEMSPEC_TEMPLATE = <<_____
Gem::Specification.new do |s|
  s.name        = "<%= executable_name %>"
  s.version     = "<%= version %>"
  s.authors     << "<%= author %>"
  s.summary     = <<EOF
<%= command.describe[/.+$/] %>
EOF
  s.description = <<EOF
<%= command.help %>
EOF
  s.files       += %w[ <%= gem_files.join(',') %> ]
  s.executables << '<%= executable_name %>'
  s.add_runtime_dependency 'ing', '~><%= [Ing::VERSION_MAJOR, Ing::VERSION_MINOR].join('.') %>'
  <% runtime_deps.each do |r| %>
  s.add_runtime_dependency '<%= r %>'
  <% end %>
end
_____
      
      DEFAULTS = {
         namespace: 'object',
         ing_file:  'ing.rb',
         bindir:    'bin',
         version:   '0.0.1',
         pretend:   false,
         install:   true,
         cleanup:   false,
         author:    ENV['USER']
      }

      def self.specify_options(parser)
        parser.text "Build and install a gem executable for the given command"
        parser.opt :author, "Gem author", :default=>DEFAULTS[:author]
        parser.opt :bindir, "Executable directory", :type=>:string, 
                     :default=>DEFAULTS[:bindir]
        # TODO implement cleanup
        parser.opt :cleanup, "Remove gems, gemspecs, and executables after install",
                     :default=>DEFAULTS[:cleanup], :short=>:z
        parser.opt :deps, "Gem files and runtime dependencies to include", :type=>:strings, :short=>:g
        parser.opt :install, "Install gem after build", 
                     :default=>DEFAULTS[:install], :short=>:x
        parser.opt :name, "Name of executable", :type=>:string, :short=>:e
        parser.opt :pretend, "Do not write files or build/install gems", 
                     :default=>DEFAULTS[:pretend]
        parser.opt :version, "Version of gem", :type=>:string,
                     :default=>DEFAULTS[:version]
      end
      
      include Ing::CommonOptions
      include Ing::Files
      
      def bindir;   options[:bindir];     end
      def version;  options[:version];    end
      def author;   options[:author];     end
      def pretend?; !!options[:pretend];  end
      
      def executable_name
        @executable_name ||= (options[:name_given] ? options[:name] : nil)
      end
      
      def executable_file
        File.join(bindir, executable_name)
      end
      
      def gemspec_file
        "#{executable_name}.gemspec"
      end

      def deps
        options[:deps] || []
      end
            
      def gem_files
        deps.select {|r| /\A(:?\.|\/)/ =~ r}
      end    

      def gem_files_from_bindir
        gem_files.map {|f|
          relative_path_from_bindir(f)
        }
      end
      
      def runtime_deps
        deps - gem_files
      end
      
      def relative_path_from_bindir(file)
        sub = Pathname.new(File.expand_path(bindir))
        f   = Pathname.new(File.expand_path(file))
        f.relative_path_from(sub)
      end
      
      def destination_root
        Dir.pwd
      end

      def source_root
        File.expand_path(File.dirname(__FILE__))
      end
      
      attr_writer :executable_name
      attr_accessor :options, :command, :shell
  
      def initialize(options)
        self.options = options
      end
      
      def before(*args)
        @before ||= begin
          require_libs
          require_ing_file
          self.shell = shell_class.new
          _init_command(*args)
          true
        end
      end

      def after
      end
      
      def call(ns=nil, *args)
        before ns, *args
        bin; gemspec; build; install if options[:install]
      end
      
      def bin(ns=nil, *args)
        before ns, *args
        create_file self.executable_file,
                    _erb.new(EXECUTABLE_TEMPLATE).result(binding)
      end
      
      def gemspec(ns=nil, *args)
        before ns, *args
        create_file self.gemspec_file,
                    _erb.new(GEMSPEC_TEMPLATE).result(binding)
      end
      
      def build(ns=nil, *args)
        before ns, *args
        x = "gem build #{self.gemspec_file}"
        pretend? ? shell.say(x) : `#{x}`
      end
      
      def install(ns=nil, *args)
        before ns, *args
        x = "gem install #{self.executable_name}-#{self.version} --local"
        pretend? ? shell.say(x) : `#{x}`
      end
      
      private
      
      def _init_command(ns, *args)
        self.command = Ing::Command.new(_namespace_class(ns), *args)
        self.executable_name ||= _executable_name_from_command(self.command)
      end
      
      def _namespace_class(ns=options[:namespace])
        Ing::Util.decode_class(ns)
      end      
      
      def _executable_name_from_command(cmd)
        'ing-' + Ing::Util.encode_class(cmd.command_class).gsub(':','-')
      end

      def _erb
        @_erb ||= begin
          require 'erubis'
          Erubis::Eruby
        rescue LoadError, NameError
          require 'erb'
          ERB
        end
      end
      
    end
  end
end