# Translates Thor's example
# https://github.com/wycats/thor/wiki/Invocations
#
module Invoking

  class Counter

    def initialize(options); end
    
    def one
      puts 1
      Ing.invoke self.class, :two
      Ing.invoke self.class, :three
    end

    def two
      puts 2
      Ing.invoke self.class, :three
    end

    def three
      puts 3
    end
  end
  
end

module Executing

  class Counter

    def initialize(options); end
    
    def one
      puts 1
      Ing.execute self.class, :two
      Ing.execute self.class, :three
    end

    def two
      puts 2
      Ing.execute self.class, :three
    end

    def three
      puts 3
    end
  end
  
end