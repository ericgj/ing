require File.expand_path('../test_helper', File.dirname(__FILE__))

# These don't test much, basically just the `extract_boot_class!` logic.
# More comprehensive tests under acceptance/ing_run_tests.
#
describe Ing do

  #-----------------------------------------------------------------------------
  describe ".run" do
      
    def mock_command_execute(klass, args)
      cmd = MiniTest::Mock.new
      cmd.expect(:execute, nil)
      cmd.expect(:command_class, nil)
      cmd.expect(:command_meth, nil)
      cmdclass = MiniTest::Mock.new
      cmdclass.expect(:new, cmd, [klass] + args)
      cmdclass
    end
    
    def stubbing_command_execute(klass, args)
      ::Ing.stub(:command, mock_command_execute(klass, args)) do |stub|
        #puts stub.command.inspect
        yield
      end
    end
    
    def mock_callstack_push(klass, meth)
      callst = MiniTest::Mock.new
      callst.expect(:push, nil, [klass, meth])
      callst
    end
    
    def stubbing_callstack_push(klass, meth)
      ::Ing.stub(:_callstack, mock_callstack_push(klass, meth)) do |stub|
        yield
      end
    end
    
    
    describe "when first arg is built-in command" do
      subject { ["generate"] + args }
      let(:args) { ["something"] }

      it "should execute with the specified command class and remaining args" do
        stubbing_command_execute(::Ing::Commands::Generate, args) do
          Ing.run subject
        end
      end
      
    end
    
    describe "when first arg is not a built-in command" do
      subject    { ["foo:die"] + args }
      let(:args) { ["do_it"] }
      
      it "should execute with the implicit command class and whole command line" do
        stubbing_command_execute(::Ing::Commands::Implicit, subject) do
          Ing.run subject
        end
      end
    end
    
  end
  
  
end
