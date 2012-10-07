require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path("../../lib/ing/files", File.dirname(__FILE__))

describe Ing::Files::Directory do
  include TestHelpers
  
  def reset
    ::FileUtils.rm_rf(destination_root)
    invoker.class.send(:define_method, :file_name, Proc.new{ "rdoc" })
  end

  def invoker
    @invoker ||= begin
      wg=WhinyGenerator.new({})
      wg.destination_root = destination_root
      wg.call 1,2
      wg
    end
  end

  def revoker
    @revoker ||= begin
      wg=WhinyGenerator.new({:revoke => true}) 
      wg.destination_root = destination_root
      wg.call 1,2
      wg
    end
  end

  def invoke!(*args, &block)
    capture(:stdout){ invoker.directory(*args, &block) }
  end

  def revoke!(*args, &block)
    capture(:stdout){ revoker.directory(*args, &block) }
  end

  def exists_and_identical?(source_path, destination_path)
    %w(config.rb README).each do |file|
      source      = File.join(source_root, source_path, file)
      destination = File.join(destination_root, destination_path, file)

      assert File.exists?(destination)
      assert FileUtils.identical?(source, destination)
    end
  end

  describe "#invoke!" do
  
    before { reset }
    
    it "raises an error if the source does not exist" do
      assert_match(
        /Could not find "unknown" in any of your source paths/,
        assert_raises(Ing::FileNotFoundError) { invoke! "unknown" }.message
      )
    end

    it "should not create a directory in pretend mode" do
      invoke! "doc", "ghost", :pretend => true
      refute File.exists?("ghost")
    end

    it "copies the whole directory recursively to the default destination" do
      invoke! "doc"
      exists_and_identical?("doc", "doc")
    end

    it "copies the whole directory recursively to the specified destination" do
      invoke! "doc", "docs"
      exists_and_identical?("doc", "docs")
    end

    it "copies only the first level files if not recursive" do
      invoke! ".", "tasks", :recursive => false

      file = File.join(destination_root, "tasks", "group.ing.rb")
      assert File.exists?(file)

      file = File.join(destination_root, "tasks", "doc")
      refute File.exists?(file)

      file = File.join(destination_root, "tasks", "doc", "README")
      refute File.exists?(file)
    end

    it "copies files from the source relative to the current path" do
      invoker.inside "doc" do
        invoke! "."
      end
      exists_and_identical?("doc", "doc")
    end

    it "copies and evaluates templates" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "rdoc.rb")
      assert File.exists?(file)
      assert_equal "FOO = FOO\n", File.read(file)
    end

    it "copies directories and preserved file mode" do
      invoke! "preserve", "preserved", :mode => :preserve
      original = File.join(source_root, "preserve", "script.sh")
      copy = File.join(destination_root, "preserved", "script.sh")
      assert_equal File.stat(original).mode, File.stat(copy).mode
    end
		
    it "copies directories" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "components")
      assert File.exists?(file)
      assert File.directory?(file)
    end

    it "does not copy .empty_directory files" do
      invoke! "doc", "docs"
      file = File.join(destination_root, "docs", "components", ".empty_directory")
      refute File.exists?(file)
    end

    it "copies directories even if they are empty" do
      invoke! "doc/components", "docs/components"
      file = File.join(destination_root, "docs", "components")
      assert File.exists?(file)
    end

    it "does not copy empty directories twice" do
      content = invoke!("doc/components", "docs/components")
      refute_match(/exist/, content)
    end

    it "logs status" do
      content = invoke!("doc")
      assert_match(/create  doc\/README/, content)
      assert_match(/create  doc\/config\.rb/, content)
      assert_match(/create  doc\/rdoc\.rb/, content)
      assert_match(/create  doc\/components/, content)
    end

    it "yields a block" do
      checked = false
      invoke!("doc") do |content|
        checked ||= !!(content =~ /FOO/)
      end
      assert checked
    end

    it "works with glob characters in the path" do
      content = invoke!("app{1}")
      assert_match(/create  app\{1\}\/README/, content)
    end
  end

  describe "#revoke!" do
    before { reset }
    
    it "removes the destination file" do
      invoke! "doc"
      revoke! "doc"

      refute File.exists?(File.join(destination_root, "doc", "README"))
      refute File.exists?(File.join(destination_root, "doc", "config.rb"))
      refute File.exists?(File.join(destination_root, "doc", "components"))
    end

    it "works with glob characters in the path" do
      invoke! "app{1}"
      assert File.exists?(File.join(destination_root, "app{1}", "README"))

      revoke! "app{1}"
      refute File.exists?(File.join(destination_root, "app{1}", "README"))
    end
  end
end
