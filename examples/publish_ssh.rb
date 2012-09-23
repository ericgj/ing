# This is a translation of Rake SSH publisher classes,
# with some improvements.
# cf. https://github.com/jimweirich/rake/blob/master/lib/rake/contrib/sshpublisher.rb
#
module Publish

  module Ssh 

    extend Ing::DefaultCommand
    default_command :Dir

    # this is a bit too obscure as a way to define a default task within a 
    # namespace... needed in order to set the shell via execute block as the
    # boot process does.
    #
    # maybe something like  extend DefaultCommand; default_command Publish:Ssh::Dir
#    class << self 
#      attr_accessor :shell
#      def call(*args)
#        Ing.execute Publish::Ssh::Dir, *args do |cmd| 
#          cmd.shell = self.shell
#        end
#      end
#    end
    
    # Base class and options for all SSH publisher classes
    # Publisher classes should at minimum define +shell_commands+ (array of shell
    # commands to be executed)
    #
    class Base < Ing::Task
      
      desc "(internal)"
      opt :host,       "Remote user@host", :type => :string
      opt :remote_dir, "Remote path", :type => :string
      opt :local_dir,  "Local path",  :type => :string, :default => Dir.pwd
      opt :pretend,    "Do not publish"
      opt :debug,      "Write shell commands to stderr"
      
      # Note prompts for +host+ and +remote_dir+ if not given
      def before
        ask_unless_given!(:host, :remote_dir)
        validate_option_exists :host
        validate_option_exists :remote_dir
      end
      
      def call
        upload
      end
      
      def upload
        before
        Array(shell_commands).each do |cmd| 
          $stderr.puts cmd if debug?
          sh cmd unless pretend?
        end
      end
            
      def shell_commands
        []
      end
      
      private
      
      def host; options[:host]; end
      def remote_dir; options[:remote_dir]; end
      def local_dir; options[:local_dir]; end
      def debug?; !!options[:debug]; end
      def pretend?; !!options[:pretend]; end
      
    end

    # +ing publish:ssh:dir+
    class Dir < Base
      desc "Publish an entire directory to an existing remote directory using SSH."
      def shell_commands
        %Q{scp -rq #{local_dir}/* #{host}:#{remote_dir}}
      end
    end
    
    # +ing publish:ssh:fresh_dir+    
    class FreshDir < Dir
      desc "Publish an entire directory to a fresh remote directory using SSH."
      
      # note send multiple cmds to single ssh session via here-doc
      def shell_commands
        cmds = ["rm -rf #{remote_dir}", "mkdir #{remote_dir}"]
        [
          %Q{ssh #{host} << EOF\n  #{cmds.join("\n  ")}\nEOF },
        ] + Array(super)
      end
    end

    # +ing publish:ssh:files+    
    class Files < Base
      desc "Publish a list of files to an existing remote directory."
      opt :files, "Files (or file globs) to copy", :type => :string, :multi => true
      
      # to allow pre-expanded file globs like
      #   ing publish:ssh:files ./*`       # instead of
      #   ing publish:ssh:files -f './*'
      #
      def call(*args)
        options[:files] += args
        super()
      end
      
      def shell_commands
        files.map { |fn|
          %Q{scp -q #{local_dir}/#{fn} #{host}:#{remote_dir}}
        }
      end
      
      private
      def files; options[:files] || []; end      
    end
    
  end
end