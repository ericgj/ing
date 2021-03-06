﻿require File.expand_path('../test_helper', File.dirname(__FILE__))

describe Ing do
  include TestHelpers
  
  def capture_run(args)
    capture(:stdout) { Ing.run args }
  end

  def reset
    Ing::Callstack.clear
  end
  
  def count_executions_of(klass, meth)
    Ing.callstack.count {|(k, m)| 
      k == klass && m == meth
    }    
  end
    
  describe "#run" do

    describe "no method or args given" do
      before { reset }
      subject { ["count_args"] }
      
      it 'should run with expected output' do 
        assert_equal "CountArgs called with 0 args", 
                     capture_run(subject).chomp
      end
      
    end
    
    describe "method given with args" do
      before { reset }
      subject { ["amazing", "describe", "Malcolm"] }
      
      it 'should run with expected output' do
        assert_equal "Malcolm is amazing", capture_run(subject).chomp
      end
      
    end
    
    describe "option args given" do
      before { reset }
      subject { ["amazing", "describe", "--forcefully", "Malcolm"] }
      
      it 'should run with expected output' do
        assert_equal "MALCOLM IS AMAZING", capture_run(subject).chomp
      end
      
      describe "and option args given at end" do
        before { reset }
        subject { ["amazing", "describe", "Malcolm", "--forcefully"] }
      
        it 'should run with expected output' do
          assert_equal "MALCOLM IS AMAZING", capture_run(subject).chomp
        end
      end
      
    end
    
    describe "unknown method given" do
      before { reset }
      subject { ["amazing", "write", "Malcolm"] }
    
      it 'should raise error' do
        assert_raises(::NoMethodError) { capture_run subject }
      end
      
    end
    
    describe "undefined option given" do
      before { reset }
      subject { ["amazing", "describe", "Malcolm", "--times=3"] }
    
      it 'should exit' do
        assert_raises(::SystemExit) { capture_run(subject) }
      end
    end
    
    describe "wrong number of args given" do
      before { reset }
      subject { ["amazing", "describe"] }
    
      it 'should raise error' do
        assert_raises(::ArgumentError) { capture_run subject }
      end    
    end
    
    describe "require boot option given" do
      before { reset }
      subject { ["-r", "./test/fixtures/require.ing", 
                 "--require", "cgi",
                 "dynamic_require"
                ] 
              }
      
      it 'should load specified files and libraries' do
        capture_run subject
        DynamicRequire; CGI
        assert true
      end
      
    end
    
    describe "namespace boot option given" do
      before { reset }
      subject { ["--require=./test/fixtures/namespace.ing",
                 "-n", "some_base_namespace",
                 "one:two:three:echo", "call", "hello world"
                ]
              }
              
      it 'should run with expected output' do
        assert_equal "hello world", capture_run(subject).chomp
      end
      
      describe "and class not within namespace" do
        before { reset }
        subject { ["--require=./test/fixtures/namespace.ing",
                   "-n", "some_base_namespace",
                   "echo", "call", "hello world"
                  ]
                }
        
        it 'should raise error' do
          assert_raises(::NameError) { capture_run(subject).chomp }
        end
        
      end
      
    end
    
    describe "dispatch to proc" do
      before { reset }
      subject { %w[p 1 2 3] }
      
      P = lambda {|*args| 
        opts = (Hash === args.last ? args.pop : {})
        args.reverse.each_with_index {|a,i| puts "#{i}:#{a}"}
      }
      
      it 'should run with expected output' do
        log = capture_run(subject).chomp
        assert_equal "0:3\n1:2\n2:1", log
      end
      
    end
    
  end
  
  describe "invoking within tasks" do
    before { reset }
    subject { ["invoking:counter", "one"] }
    
    it 'should run with expected output' do
      assert_equal "1\n2\n3\n", capture_run(subject)
    end
    
    it 'should only list one execution in the call stack for invoked commands' do
      capture_run(subject)
      assert_equal 1, count_executions_of(Invoking::Counter, :one)
      assert_equal 1, count_executions_of(Invoking::Counter, :two)
      assert_equal 1, count_executions_of(Invoking::Counter, :three)
    end
  end
  
  describe "executing within tasks" do
    before { reset }
    subject { ["executing:counter", "one"] }
    
    it 'should run with expected output' do
      assert_equal "1\n2\n3\n3\n", capture_run(subject)
    end    
    
    it 'should only list each execution in the call stack for executed commands' do
      capture_run(subject)
      assert_equal 1, count_executions_of(Executing::Counter, :one)
      assert_equal 1, count_executions_of(Executing::Counter, :two)
      assert_equal 2, count_executions_of(Executing::Counter, :three)
    end
    
  end
  
end