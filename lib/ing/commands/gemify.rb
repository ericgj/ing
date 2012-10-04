module Ing
  module Commands
  
    class Gemify

      # TODO fix this for nonstandard bindir
      EXECUTABLE_TEMPLATE = <<_____
#!/usr/bin/env ruby
require 'ing'
require File.expand_path('../<%= ing_file %>', File.dirname(__FILE__))
<% relative_requires.each do |r| %>
require File.expand_path('../<%= r %>', File.dirname(__FILE__))
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
  s.files       << '<%= ing_file %>'
  s.files       += %w[ <%= relative_requires.join(',') %> ]
  s.executables << '<%= executable_name %>'
  s.add_runtime_dependency 'ing', '~><%= Ing::VERSION %>'
  <% gem_requires.each do |r| %>
  s.add_runtime_dependency '<%= r %>'
  <% end %>
end
_____
      
      DEFAULTS = {
         namespace: 'object',
         ing_file:  'ing.rb',
         bindir:    'bin',
         version:   '0.0.1',
         install:   true,
         cleanup:   false,
         author:    ENV['USER']
      }

      def self.specify_options(parser)
        parser.text "Build and install a gem executable for the given command"
        parser.opt :author, "Gem author", :default=>DEFAULTS[:author]
        parser.opt :bindir, "Executable directory", :type=>:string, 
                     :default=>DEFAULTS[:bindir]
        parser.opt :install, "Install gem after build", 
                     :default=>DEFAULTS[:install]
        parser.opt :name, "Name of executable", :type=>:string
        parser.opt :cleanup, "Remove gems, gemspecs, and executables after install",
                     :default=>DEFAULTS[:cleanup]
        parser.opt :version, "Version of gem", :type=>:string,
                     :default=>DEFAULTS[:version]
        parser.stop_on_unknown
      end
      
      include Ing::CommonOptions
      
      def bindir;  options[:bindir];    end
      def version; options[:version];  end
      def author;  options[:author];  end
      
      def executable_name
        @executable_name ||= (options[:name_given] ? options[:name] : nil)
      end
      
      def executable_file
        File.join(bindir, executable_name)
      end
      
      def gemspec_file
        "#{executable_name}.gemspec"
      end
      
      def relative_requires
        requires.select {|r| /\A(:?\.|\/)/ =~ r}
      end
      
      def gem_requires
        requires - relative_requires
      end
      
      attr_writer :executable_name
      attr_accessor :options, :command
      def initialize(options)
        self.options = options
      end
      
      def before(*args)
        @before ||= begin
          require_libs
          require_ing_file
          _init_command(*args)
          true
        end
      end

      def call(ns=nil, *args)
        before ns, *args
        bin; gemspec; build; install if options[:install]
      end
      
      def bin(ns=nil, *args)
        before ns, *args
        File.open(self.executable_file, 'w+') do |f|
          f.write _erb.new(EXECUTABLE_TEMPLATE).result(binding)
        end
      end
      
      def gemspec(ns=nil, *args)
        before ns, *args
        File.open(self.gemspec_file, 'w+') do |f|
          f.write _erb.new(GEMSPEC_TEMPLATE).result(binding)
        end
      end
      
      def build(ns=nil, *args)
        before ns, *args
        `gem build #{self.gemspec_file}`
      end
      
      def install(ns=nil, *args)
        before ns, *args
        `gem install #{self.executable_name}-#{self.version} --local`
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
        Ing::Util.encode_class(cmd.command_class).gsub(':','-')
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