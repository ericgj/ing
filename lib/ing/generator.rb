module Ing
  class Generator < Task
        
    desc "(internal)"
    opt :dest, "Destination root", :type => :string
    opt :source, "Source root", :type => :string
    opt :verbose, "Run verbosely by default"
    opt :force, "Overwrite files that already exist"
    opt :pretend, "Run but do not make any changes"
    opt :revoke, "Revoke action (not available for all generators)"
    opt :quiet, "Suppress status output"
    opt :skip, "Skip files that already exist"
        
    include Ing::Files
        
    # Destination root for filesystem actions
    def destination_root
      File.expand_path(options[:dest])
    end
    
    # Source root for filesystem actions
    def source_root
      File.expand_path(options[:source])
    end
    
    def initialize(options)
      super
      validate_option_exists :dest, 'destination_root'
      validate_option_exists :source, 'source_root'
    end
        
  end
end