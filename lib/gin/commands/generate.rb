module Gin

  class Generate
    extend Gin::Options
    
    option "--gen-root [DIR]", "Root for generate"

    
    def self.call(name, opts={})
      new(name).call(opts)
    end
    
    def initialize(name)
    end
    
    def call(opts={})
      
    end
    
  end
  
  # alias
  G = Generate
  
end