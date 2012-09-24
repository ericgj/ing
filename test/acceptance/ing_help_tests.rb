require File.expand_path('../test_helper', File.dirname(__FILE__))

describe Ing::Commands::Help do
  include TestHelpers
  
  def capture_run(args)
    capture(:stdout) { Ing.run args }
  end

  def reset
    Ing::Callstack.clear
  end
  
  describe "no namespace, no args" do
  
    subject { [ "help" ] }
    before  { reset }
    
    it 'should display help on help' do
      output = capture_run(subject)
      assert_match(/Display help on specified command/i, output)
    end
    
  end
  
  describe "no namespace, single arg with namespaced command" do
  
    subject { [ "help", "helping:one" ] }
    before { reset }
    
    it 'should display help on task named in arg' do
      output = capture_run(subject)
      assert_match(/This is the help for helping:one/i, output)
    end
  end

  describe "no namespace, single arg with non-namespaced command" do
  
    subject { [ "help", "generate" ] }
    before { reset }
    
    it 'should display help on task named in arg within namespace ing:commands' do
      output = capture_run(subject)
      assert_match(/Run a generator task/i, output)
    end
  end

  describe "namespace, no arg" do
    
    subject { [ "help", "--namespace", "helping" ] }
    before { reset }
  
    it 'should display help on specified namespace' do
    
    end
  end
  
  describe "namespace, single arg with namespaced command" do
  
    subject { [ "help", "--namespace", "helping", "sub:one" ] }
    before { reset }
    
    it 'should display help on task named in arg under specified namespace' do
      output = capture_run(subject)
      assert_match(/This is the help for helping:sub:one/i, output)
    end
  end
  
  describe "namespace, single arg with non-namespaced command" do
  
    subject { [ "help", "--namespace", "helping:sub", "one" ] }
    before { reset }
    
    it 'should display help on task named in arg under specified namespace' do
      output = capture_run(subject)
      assert_match(/This is the help for helping:sub:one/i, output)
    end
  end
  
end