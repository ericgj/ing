module SomeBaseNamespace

  module One
  
    module Two
    
      module Three
      
        class Echo
        
          def initialize(options); end
          
          def call(arg)
            puts arg
          end
          
        end
        
      end
      
    end
    
  end
  
end

module One
  module Two
    module Three
      class Echo
        
        def initialize(options); end
        
        def call(arg)
          puts "wrong"
        end
             
      end

    end
  end
end

class Echo
  
  def initialize(options); end
  
  def call(arg)
    puts "also wrong"
  end
       
end
