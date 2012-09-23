require 'rake-pipeline'

# This is Rake::Pipeline::CLI rewritten as an Ing task
# instead of Thor
# cf. https://github.com/livingsocial/rake-pipeline
#
# Stick this in your ing.rb and you can simply run
#
#   ing pipeline:build
#
# to build your project, or
#
#   ing pipeline
#
# to start the preview server (equivalent to +rakep+)
#         
module Pipeline

  # default == server
  extend Ing::DefaultCommand
  default_command :Server

  module Helpers

    private
    
    def project
      @project ||= Rake::Pipeline::Project.new(options[:assetfile])
    end

    # @param [FileWrapper|String] path
    # @return [String] The path to the file with the current
    #   directory stripped out.
    def relative_path(path)
      pathstr = path.respond_to?(:fullpath) ? path.fullpath : path
      pathstr.sub(%r|#{Dir.pwd}/|, '')
    end
          
  end
 
  class Build < Ing::Task
    include Helpers
    
    desc "Build the project."
    usage "  ing pipeline build"
    opt :assetfile, "Asset file", :default => "Assetfile", :short => "c"
    opt :pretend
    opt :clean, "Clean before building"
    
    # ing pipeline build
    def call
      if options[:pretend]
        project.output_files.each do |file|
          shell.say_status :create, relative_path(file)
        end
      else
        options[:clean] ? Ing.invoke(Clean, options) : project.cleanup_tmpdir
        project.invoke
      end
    end

  end
  
  class Clean < Ing::Task
    include Helpers
  
    desc "Remove the pipeline's temporary and output files."
    usage "  ing pipeline clean"
    opt :pretend
          
    # ing pipeline clean
    def call
      if options[:pretend]
        project.files_to_clean.each do |file|
          shell.say_status :remove, relative_path(file)
        end
      else
        project.clean
      end
    end

  end
  
  class Server < Ing::Task
    
    desc  "Run the Rake::Pipeline preview server (default task)."
    usage "  ing pipeline server"
    
    # ing pipeline server
    def call
      require "rake-pipeline/server"
      Rake::Pipeline::Server.new.start
    end

  end
    
end