module Ing
  class Generator < Task
        
    opt :dest, "Destination root", :type => :string
    opt :source, "Source root", :type => :string
        
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