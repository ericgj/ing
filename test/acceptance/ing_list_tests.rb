require File.expand_path('../test_helper', File.dirname(__FILE__))

describe Ing::Commands::List do
  include TestHelpers
  
  def capture_run(args)
    capture(:stdout) { Ing.run args }
  end

  def reset
    Ing::Callstack.clear
  end
  
  describe "namespace given, no args" do
  
    subject { [ "list", "-n", "listing" ] }
    before  { reset }
    
    it "should list all tasks that have a description within namespace" do
      output = capture_run(subject)
      assert_match(/ing listing:one\s/, output)
      assert_match(/ing listing:two\s/, output)
      assert_match(/ing listing:three\s/, output)
    end
    
    it "should list tasks within nested namespaces" do
      output = capture_run(subject)
      assert_match(/ing listing:sub\s/, output)
      assert_match(/ing listing:sub:one\s/, output)
      assert_match(/ing listing:sub:two\s/, output)
    end
    
    it "should not list tasks that do not have a description" do
      output = capture_run(subject)
      refute_match(/ing listing:no_desc/, output)
    end
    
  end
  
  describe "namespace given, no args, --all" do
  
    subject { [ "list", "-n", "listing", "--all" ] }
    before  { reset }

    it "should list tasks that do not have a description" do
      output = capture_run(subject)
      assert_match(/ing listing:no_desc:one\s/, output)
      assert_match(/ing listing:no_desc:two\s/, output)
      assert_match(/ing listing:no_desc:three\s/, output)
    end
    
  end
  
  describe "namespace given, no args, --strict" do
  
    subject { [ "list", "-n", "listing", "--strict" ] }
    before  { reset }

    it "should list all tasks that have a description within namespace" do
      output = capture_run(subject)
      assert_match(/ing listing:one\s/, output)
      assert_match(/ing listing:two\s/, output)
      assert_match(/ing listing:three\s/, output)
      assert_match(/ing listing:sub\s/, output)
    end
    
    it "should not list tasks within nested namespaces" do
      output = capture_run(subject)
      refute_match(/ing listing:sub:one\s/, output)
      refute_match(/ing listing:sub:two\s/, output)
    end
    
    it "should not list tasks that do not have a description" do
      output = capture_run(subject)
      refute_match(/ing listing:no_desc/, output)
    end
    
  end
  
  describe "namespace given with search arg" do
  
    subject { [ "list", "-n", "listing", "one" ] }
    before  { reset }
    
    it "should list all tasks within namespace that include search text and that have a description" do
      output = capture_run(subject)
      assert_match(/ing listing:one\s/, output)
      assert_match(/ing listing:none\s/, output)
    end
    
    it "should list matching tasks in nested namespaces" do
      output = capture_run(subject)
      assert_match(/ing listing:sub:one\s/, output)
      assert_match(/ing listing:sub:none\s/, output)
    end

    it "should not list tasks that do not have a description" do
      output = capture_run(subject)
      refute_match(/ing listing:no_desc/, output)
    end
    
  end
  
  describe "namespace given with search arg, --all" do
  
    subject { [ "list", "-n", "listing", "--all", "one" ] }
    before  { reset }

    it "should list tasks that do not have a description" do
      output = capture_run(subject)
      assert_match(/ing listing:no_desc:one\s/, output)
      assert_match(/ing listing:no_desc:none\s/, output)
    end
    
  end
  
  describe "namespace given with search arg, --strict" do
  
    subject { [ "list", "-n", "listing", "--strict", "one" ] }
    before  { reset }

    it "should list all tasks that have a description within namespace" do
      output = capture_run(subject)
      assert_match(/ing listing:one\s/, output)
      assert_match(/ing listing:none\s/, output)
    end
    
    it "should not list tasks within nested namespaces" do
      output = capture_run(subject)
      refute_match(/ing listing:sub:one\s/, output)
      refute_match(/ing listing:sub:none\s/, output)
    end
    
    it "should not list tasks that do not have a description" do
      output = capture_run(subject)
      refute_match(/ing listing:no_desc/, output)
    end
    
  end
  
end