require File.expand_path('../test_helper', File.dirname(__FILE__))

describe Ing::Task do
  include TestHelpers
  
  def capture_help(args)
    capture(:stdout) { Ing.run ["help", "-n", "object"] + args }
  end

  def capture_run(args)
    capture(:stdout) { Ing.run args }
  end
  
  describe "single inheritance" do
  
    subject { ["simple_task"] }
    
    it "help should display the description, followed by usage, followed by options" do
      lines = capture_help(subject).split("\n")
      assert_equal 9, lines.length
      assert_equal "My great task of immense importance", lines[0]
      assert_equal "A simple example of a task using Ing::Task", lines[1]
      assert_empty lines[2]
      assert_equal "Usage:", lines[3]
      assert_equal "  ing simple_task [OPTIONS]", lines[4]
      assert_empty lines[5]
      assert_equal "Options:", lines[6]
      assert_match /--fast/, lines[7]
      assert_match /--altitude/, lines[8]
    end
    
  end

  describe "double inheritance" do
  
    subject { ["big_task"] }
    
    it "help should display all the options defined by the task and its superclass" do
      output = capture_help(subject)
      assert_match(/^\s*--fast/, output)
      assert_match(/^\s*--altitude/, output)
      assert_match(/^\s*--yards/, output)
      assert_match(/^\s*--color/, output)
    end
    
    it "run should reflect modifications to superclass options" do
      output = capture_help(subject)
      assert_match(/^\s*--fast.+\(default: true\)/, output)
      assert_match(/^\s*--altitude\, -l.+\(default: 2500\)/, output)      
    end
    
  end
  
end