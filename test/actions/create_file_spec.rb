require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path("../../lib/ing/files", File.dirname(__FILE__))

describe Ing::Files::CreateFile do
  include SpecHelpers
  
  def reset
    ARGV.replace []
    ::FileUtils.rm_rf(destination_root)
  end

  def create_file(destination=nil, config={}, options={})
    @base = MyCounter.new(options)
    @base.destination_root = destination_root
    MyCounter.send(:define_method, :file_name, Proc.new {'rdoc'} )

    @action = Ing::Files::CreateFile.new(@base, destination, "CONFIGURATION",
                                            { :verbose => !@silence }.merge(config))
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def revoke!
    capture(:stdout){ @action.revoke! }
  end

  def silence!
    @silence = true
  end

  # stubs multiple input responses from $stdin.gets
  # not currently used
  class StubInput
  
    def initialize(expected)
      @s = Array(expected)
    end
    
    def gets
      @s.shift
    end
    
    def reply_for(stream=$stdin, &b)
      stream.stub(:gets, self.method(:gets), &b)
    end
    
  end
  
  describe "#invoke!" do
    before { reset }
    
    it "creates a file" do
      create_file("doc/config.rb")
      invoke!
      assert File.exists?(File.join(destination_root, "doc/config.rb"))
    end

    it "does not create a file if pretending" do
      create_file("doc/config.rb", {}, :pretend => true)
      invoke!
      refute File.exists?(File.join(destination_root, "doc/config.rb"))
    end

    it "shows created status to the user" do
      create_file("doc/config.rb")
      assert_equal "      create  doc/config.rb\n", invoke!
    end

    it "does not show any information if log status is false" do
      silence!
      create_file("doc/config.rb")
      assert_empty invoke!
    end

    it "returns the given destination" do
      capture(:stdout) do
        assert_equal "doc/config.rb", create_file("doc/config.rb").invoke!
      end
    end

    it "converts encoded instructions" do
      create_file("doc/%file_name%.rb.tt")
      invoke!
      assert File.exists?(File.join(destination_root, "doc/rdoc.rb.tt"))
    end

    describe "when file exists" do

      describe "and is identical" do
        before do
          reset
          create_file("doc/config.rb")
          invoke!
        end

        it "shows identical status" do
          create_file("doc/config.rb")
          invoke!
          assert_equal "   identical  doc/config.rb\n", invoke!
        end
      end

      describe "and is not identical" do
        before do
          reset
          create_file("doc/config.rb")
          invoke!          
          File.open(File.join(destination_root, 'doc/config.rb'), 'w'){ |f| f.write("FOO = 3") }
        end

        it "shows forced status to the user if force is given" do
          refute create_file("doc/config.rb", {}, :force => true).identical?
          assert_equal "       force  doc/config.rb\n", invoke!
        end

        it "shows skipped status to the user if skip is given" do
          refute create_file("doc/config.rb", {}, :skip => true).identical?
          assert_equal "        skip  doc/config.rb\n", invoke!
        end

        it "shows forced status to the user if force is configured" do
          refute create_file("doc/config.rb", :force => true).identical?
          assert_equal "       force  doc/config.rb\n", invoke!
        end

        it "shows skipped status to the user if skip is configured" do
          refute create_file("doc/config.rb", :skip => true).identical?
          assert_equal "        skip  doc/config.rb\n", invoke!
        end

        it "shows conflict status to ther user" do
          refute create_file("doc/config.rb").identical?
          file = File.join(destination_root, 'doc/config.rb')
          content = nil
          $stdin.stub(:gets,'s') do
            content = invoke!
          end
          assert_match(/conflict  doc\/config\.rb/, content)
          assert_match(/Overwrite #{file}\? \(enter "h" for help\) \[Ynaqdh\]/, content)
          assert_match(/skip  doc\/config\.rb/, content)
        end

        it "creates the file if the file collision menu returns true" do
          create_file("doc/config.rb")
          $stdin.stub(:gets,'y') do
            assert_match(/force  doc\/config\.rb/, invoke!)
          end
        end

        it "skips the file if the file collision menu returns false" do
          create_file("doc/config.rb")
          $stdin.stub(:gets,'n') do
            assert_match(/skip  doc\/config\.rb/, invoke!)
          end
        end

# Not sure how to do the mock method here without more flexible mocks....
#        it "executes the block given to show file content" do
#          create_file("doc/config.rb")
#          $stdin.should_receive(:gets).and_return('d')
#          $stdin.should_receive(:gets).and_return('n')
#          @base.shell.should_receive(:system).with(/diff -u/)
#          invoke!
#        end

      end
    end
  end  
  
  describe "#revoke!" do
    before { reset }
    
    it "removes the destination file" do
      create_file("doc/config.rb")
      invoke!
      revoke!
      refute File.exists?(@action.destination)
    end

    it "does not raise an error if the file does not exist" do
      create_file("doc/config.rb")
      revoke!
      refute File.exists?(@action.destination)
    end
  end

  describe "#exists?" do
    before { reset }
    it "returns true if the destination file exists" do
      create_file("doc/config.rb")
      refute @action.exists?
      invoke!
      assert @action.exists?
    end
  end

  describe "#identical?" do
    before { reset }
    it "returns true if the destination file and is identical" do
      create_file("doc/config.rb")
      refute @action.identical?
      invoke!
      assert @action.identical?
    end
  end
end
