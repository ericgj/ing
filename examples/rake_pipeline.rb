require 'rake-pipeline'
  
  # This is Rake::Pipeline::CLI rewritten as an Ing task
  # instead of Thor
  # cf. https://github.com/livingsocial/rake-pipeline
  #
  # Stick this in your ing.rb and you can simply run
  #   ing pipeline
  # to build your project.
  # 
  # Namespace it if you wish; but note Rake::Pipeline is already taken.
  #
  class Pipeline < Ing::Task
  
    desc "Rake pipeline"
    usage "  ing pipeline build   " +
          "# Build the project (default task)."
    usage "  ing pipeline clean   " +
          "# Remove the pipeline's temporary and output files."
    usage "  ing pipeline server  " +
          "# Run the Rake::Pipeline preview server."
    opt :assetfile, "Asset file", :default => "Assetfile", :short => "c"
    opt :pretend
    opt :clean, "Clean before building"

    # ing pipeline
    # default task == build
    def call
      build
    end
    
    # ing pipeline build
    def build
      if options[:pretend]
        project.output_files.each do |file|
          shell.say_status :create, relative_path(file)
        end
      else
        options[:clean] ? clean : project.cleanup_tmpdir
        project.invoke
      end
    end

    # ing pipeline clean
    def clean
      if options[:pretend]
        project.files_to_clean.each do |file|
          say_status :remove, relative_path(file)
        end
      else
        project.clean
      end
    end
    
    # ing pipeline server
    def server
      require "rake-pipeline/server"
      Rake::Pipeline::Server.new.start
    end

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
  