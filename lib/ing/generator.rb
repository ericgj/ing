module Ing
  class Generator < Task
        
    opt :dest, "Destination root", :type => :string
    opt :source, "Source root", :type => :string
        
    include Ing::Files
        
    def destination_root
      File.expand_path(options[:dest])
    end
    
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