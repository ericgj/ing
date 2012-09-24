module Helping

  def self.specify_options(p)
    p.text "This is the help for helping"
  end
  
  class One
    def self.specify_options(p)
      p.text "This is the help for helping:one"
    end
  end
  
  module Sub
  
    class One
      def self.specify_options(p)
        p.text "This is the help for helping:sub:one"
      end    
    end
    
  end
  
end