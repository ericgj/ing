﻿# Note: these are Ing::Files fixtures
# used in actions specs adapted from Thor

class MyCounter

  def self.specify_options(expect)
    expect.opt :third, "The third argument", :type => :numeric, :default => 3,
                        :short => "t"
    expect.opt :fourth, "The fourth argument", :type => :numeric  
    expect.banner "This generator runs three tasks: one, two and three."
  end
  
  include Ing::Files
  
  def source_root 
    File.expand_path(File.dirname(__FILE__))
  end
  
  attr_accessor :destination_root, :options, :first, :second, :shell
  
  def shell
    @shell ||= Ing::Shell::Basic.new
  end
  
  def initialize(options)
    self.options = options
  end
  
  def call(*args)
    self.first, self.second = args.shift, args.shift
    one; two; three
  end
  
  def one
    first
  end

  def two
    second
  end

  def three
    options[:third]
  end
  
  def world(&block)
    result = capture(&block)
    concat(result.strip + " world!")
  end
    
end


class WhinyGenerator
  include Ing::Files

  def source_root
    File.expand_path(File.dirname(__FILE__))
  end

  attr_accessor :destination_root, :options, :shell
  
  def shell
    @shell ||= Ing::Shell::Basic.new
  end

  def initialize(options)
    self.options = options
  end
  
  def call(*args)
  end
  
  def wrong_arity(required)
  end
end