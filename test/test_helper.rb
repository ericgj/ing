gem 'minitest'
require 'minitest/autorun'

require File.expand_path('../lib/ing', File.dirname(__FILE__))

ARGV.clear

# Load fixtures
load File.join(File.dirname(__FILE__), "fixtures", "group.ing.rb")

module TestHelpers

  def source_root
    File.join(File.dirname(__FILE__), 'fixtures')
  end

  def destination_root
    File.join(File.dirname(__FILE__), 'sandbox')
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
  alias :silence :capture
  
end

SpecHelpers = TestHelpers
