
module Listing

  class One < Ing::Task
  
    desc "A sample task implemented as Ing::Task"
    
    def call(*args); end
  end
  
  class None < Ing::Task
    desc "Sample task that should come up in searches for 'one'"
    def call(*args); end
  end
  
  class Two
  
    def self.specify_options(p)
      p.text "A sample task implemented as plain ruby"
    end
    
    attr_accessor :shell
    def initialize(options); end
    def call(*args); end
    
  end
  
  Three = Proc.new {|*args| }
  def Three.specify_options(p)
    p.text "A sample task implemented as a Proc"
  end
  
  module Sub
  
    def self.specify_options(p)
      p.text "A sample task implemented as a callable module"
    end
    
    def self.call(*args); end
   
    class One < Ing::Task
      desc "Task listing:sub:one"
      def call(*args); end
    end
  
    class Two < Ing::Task
      desc "Task listing:sub:two"
      def call(*args); end
    end
    
    class None < Ing::Task
      desc "Task listing:sub:none should come up in searches for 'one'"
      def call(*args); end
    end
    
  end
  
  module NoDesc
  
    class One
    end
    
    module Two
    end  
    
    Three = Proc.new {}
    
    class None
    end
    
  end
  
end