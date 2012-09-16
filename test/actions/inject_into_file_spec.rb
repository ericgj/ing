require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path("../../lib/ing/files", File.dirname(__FILE__))

describe Ing::Files::InjectIntoFile do
  include SpecHelpers
  
  def reset
    ::FileUtils.rm_rf(destination_root)
    ::FileUtils.cp_r(source_root, destination_root)
  end

  def invoker(options={})
    @invoker ||= begin
      i = MyCounter.new(options)
      i.destination_root = destination_root
      i.call 1,2
      i
    end
  end

  def revoker
    @revoker ||= begin
      r = MyCounter.new({:revoke => true})
      r.destination_root = destination_root
      r.call 1,2
      r
    end
  end

  def invoke!(*args, &block)
    capture(:stdout){ invoker.insert_into_file(*args, &block) }
  end

  def revoke!(*args, &block)
    capture(:stdout){ revoker.insert_into_file(*args, &block) }
  end

  def file
    File.join(destination_root, "doc/README")
  end

  describe "#invoke!" do
    before { reset }
    
    it "changes the file adding content after the flag" do
      invoke! "doc/README", "\nmore content", :after => "__start__"
      assert_equal "__start__\nmore content\nREADME\n__end__\n", File.read(file)
    end

    it "changes the file adding content before the flag" do
      invoke! "doc/README", "more content\n", :before => "__end__"
      assert_equal "__start__\nREADME\nmore content\n__end__\n", File.read(file)
    end

    it "accepts data as a block" do
      invoke! "doc/README", :before => "__end__" do
        "more content\n"
      end
      assert_equal "__start__\nREADME\nmore content\n__end__\n", File.read(file)
    end

    it "logs status" do
      assert_equal "      insert  doc/README\n", 
                   invoke!("doc/README", "\nmore content", :after => "__start__")
    end

    it "does not change the file if pretending" do
      invoker :pretend => true
      invoke! "doc/README", "\nmore content", :after => "__start__"
      assert_equal "__start__\nREADME\n__end__\n", File.read(file)
    end

    it "does not change the file if already include content" do
      invoke! "doc/README", :before => "__end__" do
        "more content\n"
      end
      assert_equal "__start__\nREADME\nmore content\n__end__\n", File.read(file)

      invoke! "doc/README", :before => "__end__" do
        "more content\n"
      end
      assert_equal "__start__\nREADME\nmore content\n__end__\n", File.read(file)
    end

    it "does change the file if already include content and :force == true" do
      invoke! "doc/README", :before => "__end__" do
        "more content\n"
      end
      assert_equal "__start__\nREADME\nmore content\n__end__\n", File.read(file)

      invoke! "doc/README", :before => "__end__", :force => true do
        "more content\n"
      end
      assert_equal "__start__\nREADME\nmore content\nmore content\n__end__\n", File.read(file)
    end

  end

  describe "#revoke!" do
    before { reset }
    
    it "substracts the destination file after injection" do
      invoke! "doc/README", "\nmore content", :after => "__start__"
      revoke! "doc/README", "\nmore content", :after => "__start__"
      assert_equal "__start__\nREADME\n__end__\n", File.read(file)
    end

    it "substracts the destination file before injection" do
      invoke! "doc/README", "more content\n", :before => "__start__"
      revoke! "doc/README", "more content\n", :before => "__start__"
      assert_equal "__start__\nREADME\n__end__\n", File.read(file)
    end

    it "substracts even with double after injection" do
      invoke! "doc/README", "\nmore content", :after => "__start__"
      invoke! "doc/README", "\nanother stuff", :after => "__start__"
      revoke! "doc/README", "\nmore content", :after => "__start__"
      assert_equal "__start__\nanother stuff\nREADME\n__end__\n", File.read(file)
    end

    it "substracts even with double before injection" do
      invoke! "doc/README", "more content\n", :before => "__start__"
      invoke! "doc/README", "another stuff\n", :before => "__start__"
      revoke! "doc/README", "more content\n", :before => "__start__"
      assert_equal "another stuff\n__start__\nREADME\n__end__\n", File.read(file)
    end

    it "substracts when prepending" do
      invoke! "doc/README", "more content\n", :after => /\A/
      invoke! "doc/README", "another stuff\n", :after => /\A/
      revoke! "doc/README", "more content\n", :after => /\A/
      assert_equal "another stuff\n__start__\nREADME\n__end__\n", File.read(file)
    end

    it "substracts when appending" do
      invoke! "doc/README", "more content\n", :before => /\z/
      invoke! "doc/README", "another stuff\n", :before => /\z/
      revoke! "doc/README", "more content\n", :before => /\z/
      assert_equal "__start__\nREADME\n__end__\nanother stuff\n", File.read(file)
    end

    it "shows progress information to the user" do
      invoke!("doc/README", "\nmore content", :after => "__start__")
      assert_equal "    subtract  doc/README\n", revoke!("doc/README", "\nmore content", :after => "__start__")
    end
  end
end
