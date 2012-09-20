require File.expand_path('../test_helper', File.dirname(__FILE__))

describe Ing::Command do

  def dummy_command_class
    Class.new do
      attr_reader :options
      def initialize(options); @options = options; end
      def dummy; end
    end
  end

  def dummy_command_class_with_specify_options
    Class.new do
      def self.specify_options(expect); end
      attr_reader :options
      def initialize(options); @options = options; end
      def dummy; end
    end
  end
  
  def dummy_command_proc
    x = Proc.new { }
    def x.dummy; end
    x
  end
    
  #-----------------------------------------------------------------------------
  describe ".new" do
  
    describe "when only command class passed" do
      subject { Ing::Command.new dummy_command_class }
      
      it "should have command_meth == :call" do
        assert_equal :call, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == []" do
        assert_equal [], subject.args
      end  
    end
    
    describe "when command class and options hash passed" do
      subject       { Ing::Command.new dummy_command_class, options }
      let(:options) { {:one => 1, :two => 2} }
      
      it "should have command_meth == :call" do
        assert_equal :call, subject.command_meth
      end
      
      it "should have options == passed options" do
        assert_equal options, subject.options
      end
      
      it "should have args == []" do
        assert_equal [], subject.args
      end   
    end
    
    describe "when command class and method passed" do
      subject    { Ing::Command.new dummy_command_class, meth, *args }
      let(:meth) { "dummy" }
      let(:args) { ["one", "two"] }
      
      it "should have command_meth == passed method" do
        assert_equal meth.to_sym, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == remaining args" do
        assert_equal args, subject.args
      end   
    end
    
    describe "when command proc and method passed" do
      subject    { Ing::Command.new dummy_command_proc, meth, *args }
      let(:meth) { "dummy" }
      let(:args) { ["one", "two"] }
      
      it "should have command_meth == passed method" do
        assert_equal meth.to_sym, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == remaining args" do
        assert_equal args, subject.args
      end       
    end
    
    describe "when command class and non-public-instance-method arg passed" do
      subject    { Ing::Command.new dummy_command_class, arg, *args }
      let(:arg)  { "remove_instance_variable" }
      let(:args) { ["one", "two"] }
      
      it "should have command_meth == :call" do
        assert_equal :call, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == all passed args" do
        assert_equal [arg] + args, subject.args
      end      
    end
    
    describe "when command proc and non-public-method arg passed" do
      subject    { Ing::Command.new dummy_command_proc, arg, *args }
      let(:arg)  { "extended" }
      let(:args) { ["one", "two"] }
      
      it "should have command_meth == :call" do
        assert_equal :call, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == all passed args" do
        assert_equal [arg] + args, subject.args
      end          
    end
    
    describe "when command class and option arg passed" do
      subject    { Ing::Command.new dummy_command_class, arg, *args }
      let(:arg)  { "--nonsense" }
      let(:args) { ["one", "two"] }
      
      it "should have command_meth == :call" do
        assert_equal :call, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == all passed args" do
        assert_equal [arg] + args, subject.args
      end      
    end
    
    describe "when command proc and option arg passed" do
      subject    { Ing::Command.new dummy_command_proc, arg, *args }
      let(:arg)  { "--help" }
      let(:args) { ["one", "two"] }
      
      it "should have command_meth == :call" do
        assert_equal :call, subject.command_meth
      end
      
      it "should have options == {}" do
        assert_equal Hash.new, subject.options
      end
      
      it "should have args == all passed args" do
        assert_equal [arg] + args, subject.args
      end          
    end
    
  end
  
  #-----------------------------------------------------------------------------
  describe "#instance" do
    subject             { Ing::Command.new command_class }
    let(:command_class) { dummy_command_class }
    
    it "should return an instance of the passed class" do
      assert_kind_of command_class, subject.instance
    end
    
    describe "and passed class defines specify_options" do
      
      def mock_parser_given(args, ret={})
        parser = MiniTest::Mock.new
        parser.expect(:parser,nil)
        parser.expect(:"parse!",ret,[args]) 
        parserclass = MiniTest::Mock.new
        parserclass.expect(:new, parser)
        parserclass
      end
      
      def expecting_parser_given(args, ret={})
        Ing::Command.stub(:parser, mock_parser_given(args, ret)) do |stub|
          #puts stub.parser.inspect
          yield
        end
      end
 
# These don't work because `parse_options!` is indivisible from `instance` 
# and you need an unstubbed :command_class for `parse_options!`
#
#      def mock_command_constructor_given(opts)
#        cmd = MiniTest::Mock.new
#        cmd.expect(:new,nil,[opts])
#        cmd
#      end
#      
#      def expecting_command_constructor_given(ing_cmd, opts)
#        ing_cmd.stub(:command_class, 
#                     mock_command_constructor_given(opts)) do |stub|
#          #puts stub.command_class.inspect
#          yield
#        end
#      end
      
      subject { Ing::Command.new command_class, *args }
      let(:command_class) { dummy_command_class_with_specify_options }
      let(:args)          { ["one", "two", "three"] }
      
      it "should interact with parser as expected" do
        expecting_parser_given(args) do
          subject.instance
        end
      end
      
      describe "and an option hash is passed as the last arg" do
        subject              { Ing::Command.new command_class, *args, options }
        let(:command_class)  { dummy_command_class_with_specify_options }
        let(:args)           { ["--two", "2", "--four", "4", "--three", "1"] }
        let(:options)        { {:one => 1, :two => 2, :three => 3} }
        let(:parsed_options) { {:two => 2, :four => 4, :three => 1} }
        
        it "should merge passed options into the options parsed from other args" do
          expecting_parser_given(args, parsed_options) do
            merged_options = parsed_options.merge(options)
            it = subject.instance
            # note dummy.options returns what it was passed in constructor
            assert_equal merged_options, it.options   
          end
        end
   
      end
      
    end
    
  end
  
  #-----------------------------------------------------------------------------
  describe "#execute" do
  
    def mock_instance_sent(meth, args=[])
      inst = MiniTest::Mock.new
      inst.expect(:send, nil, [meth] + args)
      inst
    end
    
    def expecting_instance_sent(ing_cmd, meth, args=[])
      ing_cmd.stub(:instance, mock_instance_sent(meth, args)) do |stub|
        #puts stub.instance.inspect
        yield
      end
    end
    
    describe "when only command class passed" do
      subject { Ing::Command.new dummy_command_class }
      
      it "instance should receive :call and no args" do
        subject.instance
        expecting_instance_sent(subject, :call) do
          subject.execute
        end
      end
      
    end

    describe "when command class and options hash passed" do
      subject       { Ing::Command.new dummy_command_class, options }
      let(:options) { {:one => 1, :two => 2} }
    
      it "instance should receive :call and no args" do
        subject.instance
        expecting_instance_sent(subject, :call) do
          subject.execute
        end
      end
      
    end
    
    describe "when command class and method passed with args" do
      subject    { Ing::Command.new dummy_command_class, meth, *args }
      let(:meth) { "dummy" }
      let(:args) { ["one", "two"] }

      it "instance should receive passed method and args" do
        subject.instance
        expecting_instance_sent(subject, meth.to_sym, args) do
          subject.execute
        end
      end
            
    end
    
    describe "when command proc and method passed" do
      subject    { Ing::Command.new dummy_command_proc, meth, *args }
      let(:meth) { "dummy" }
      let(:args) { ["one", "two"] }
      
      it "instance should receive passed method, args, and empty options hash" do
        subject.instance
        expecting_instance_sent(subject, meth.to_sym, args + [{}]) do
          subject.execute
        end
      end
      
    end

    describe "when command proc and options hash passed" do
      subject       { Ing::Command.new dummy_command_proc, options }
      let(:options) { {:one => 1, :two => 2} }
      
      it "instance should receive :call and passed options hash" do
        subject.instance
        expecting_instance_sent(subject, :call, [options]) do
          subject.execute
        end
      end
      
    end
    
  end

end