module Foo
class Bar

    def self.specify_options(expect)
      expect.opt :foo, "Foo is on or off?"
      expect.text "A sample task"
    end

    def initialize(options); end
    def call(*args); end

end
end
