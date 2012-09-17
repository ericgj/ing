
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



class SimpleTask < Ing::Task
  
  desc  "My great task of immense importance"
  desc  "A simple example of a task using Ing::Task"
  usage "  ing simple_task [OPTIONS]"
  opt   :fast, "Run it at fast speed"
  opt   :altitude, "Start altitude", :type => :integer
  
  def call
    # ....
  end
  
end

class BigTask < SimpleTask

  desc "Even bigger!"
  opt :yards, "Yards of fishing line given", :type => :integer, :default => 25
  opt :color, "Color of cloth", :type => :string, :default => 'green'
  
  default :fast, true
  modify_option :altitude, :short => 'l', :default => 2500
  
end