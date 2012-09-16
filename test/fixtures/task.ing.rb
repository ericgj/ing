
class CountArgs

  attr_accessor :options
  
  def initialize(options)
    self.options = options
  end

  def call(*args)
    puts "#{self.class} called with #{args.length} args"
  end
  
end

class Amazing

  def self.specify_options(expect)
    expect.banner "describe NAME"
    expect.text "say that someone is amazing"
    expect.opt :forcefully
  end
  
  attr_accessor :options
  
  def initialize(options)
    self.options = options
  end
  
  def describe(name)
    ret = "#{name} is amazing"
    puts options[:forcefully] ? ret.upcase : ret
  end
  
end

