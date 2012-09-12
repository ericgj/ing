module Gin

  module Shell
  
    class Basic
    
      def debug(*args)
        stderr.puts *args
      end
      
      private
      
      def stderr
        $stderr
      end
      
    end
  
  end
  
end