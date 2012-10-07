require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path("../../lib/ing/files", File.dirname(__FILE__))

class Application; end

describe Ing::Files do
  include SpecHelpers
  
  def reset
    ::FileUtils.rm_rf(destination_root)
  end

  def runner(options={})
    @runner ||= begin
      r = MyCounter.new(options)
      r.destination_root = destination_root
      r.call 1
      r
    end
  end

  def action(*args, &block)
    capture(:stdout){ runner.send(*args, &block) }
  end

  def exists_and_identical?(source, destination)
   destination = File.join(destination_root, destination)
   assert File.exists?(destination)

   source = File.join(source_root, source)
   assert FileUtils.identical?(source, destination)
  end

  def file
    File.join(destination_root, "foo")
  end

  describe "#chmod" do
    before { reset }
    
    # A bit hacky. But really FileUtils method should not be mocked.
    def expecting_chmod(*expected_args)
      saved = FileUtils
      m = MiniTest::Mock.new; m.expect(:chmod_R, nil, expected_args)
      Object.const_set("FileUtils", m)
      yield m
    ensure
      Object.const_set("FileUtils", saved)
    end
    
    it "executes the command given" do
      expecting_chmod(0755, file) do
        action :chmod, "foo", 0755
      end
    end

### Stupid test of implementation not behavior, I'm taking it out
#    it "does not execute the command if pretending given" do
#      FileUtils.should_not_receive(:chmod_R)
#      runner(:pretend => true)
#      action :chmod, "foo", 0755
#    end

    it "logs status" do
      expecting_chmod(0755, file) do
        log = action(:chmod, "foo", 0755)
        assert_equal "       chmod  foo\n", log
      end
    end

    it "does not log status if required" do
      expecting_chmod(0755, file) do
        log = action(:chmod, "foo", 0755, :verbose => false)
        assert log.empty?
      end
    end
  end

  describe "#copy_file" do
    before { reset }
    
    it "copies file from source to default destination" do
      action :copy_file, "task.thor"
      exists_and_identical?("task.thor", "task.thor")
    end

    it "copies file from source to the specified destination" do
      action :copy_file, "task.thor", "foo.thor"
      exists_and_identical?("task.thor", "foo.thor")
    end

    it "copies file from the source relative to the current path" do
      runner.inside("doc") do
        action :copy_file, "README"
      end
      exists_and_identical?("doc/README", "doc/README")
    end

    it "copies file from source to default destination and preserves file mode" do
      action :copy_file, "preserve/script.sh", :mode => :preserve
      original = File.join(source_root, "preserve/script.sh")
      copy = File.join(destination_root, "preserve/script.sh")
      assert_equal File.stat(original).mode, File.stat(copy).mode
    end
		
    it "logs status" do
      assert_equal "      create  task.thor\n", action(:copy_file, "task.thor")
    end

    it "accepts a block to change output" do
      action :copy_file, "task.thor" do |content|
        "OMG" + content
      end
      assert_match(/^OMG/, File.read(File.join(destination_root, "task.thor")))
    end
  end

  describe "#link_file" do
    before { reset }
    
    it "links file from source to default destination" do
      action :link_file, "task.thor"
      exists_and_identical?("task.thor", "task.thor")
    end

    it "links file from source to the specified destination" do
      action :link_file, "task.thor", "foo.thor"
      exists_and_identical?("task.thor", "foo.thor")
    end

    it "links file from the source relative to the current path" do
      runner.inside("doc") do
        action :link_file, "README"
      end
      exists_and_identical?("doc/README", "doc/README")
    end

    it "logs status" do
      assert_equal "      create  task.thor\n", action(:link_file, "task.thor")
    end
  end

  describe "#get" do
    before { reset }
    
    it "copies file from source to the specified destination" do
      action :get, "doc/README", "docs/README"
      exists_and_identical?("doc/README", "docs/README")
    end

    it "uses just the source basename as destination if none is specified" do
      action :get, "doc/README"
      exists_and_identical?("doc/README", "README")
    end

    it "allows the destination to be set as a block result" do
      action(:get, "doc/README"){ |c| "docs/README" }
      exists_and_identical?("doc/README", "docs/README")
    end

    it "yields file content to a block" do
      action :get, "doc/README" do |content|
        assert_equal "__start__\nREADME\n__end__\n", content
      end
    end

    it "logs status" do
      assert_equal "      create  docs/README\n", action(:get, "doc/README", "docs/README")
    end

    it "accepts http remote sources" do
      body = "__start__\nHTTPFILE\n__end__\n"
      FakeWeb.register_uri(:get, 'http://example.com/file.txt', :body => body)
      action :get, 'http://example.com/file.txt' do |content|
        assert_equal body, content
      end
      FakeWeb.clean_registry
    end

    it "accepts https remote sources" do
      body = "__start__\nHTTPSFILE\n__end__\n"
      FakeWeb.register_uri(:get, 'https://example.com/file.txt', :body => body)
      action :get, 'https://example.com/file.txt' do |content|
        assert_equal body, content
      end
      FakeWeb.clean_registry
    end
  end

  describe "#template" do
    before { reset }
    
    it "allows using block helpers in the template" do
      action :template, "doc/block_helper.rb"

      file = File.join(destination_root, "doc/block_helper.rb")
      assert_equal "Hello world!", File.read(file)
    end

    it "evaluates the template given as source" do
      runner.instance_variable_set("@klass", "Config")
      action :template, "doc/config.rb"

      file = File.join(destination_root, "doc/config.rb")
      assert_equal "class Config; end\n", File.read(file)
    end

    it "copies the template to the specified destination" do
      action :template, "doc/config.rb", "doc/configuration.rb"
      file = File.join(destination_root, "doc/configuration.rb")
      assert File.exists?(file)
    end

    it "converts enconded instructions" do
      runner.class.send(:define_method, :file_name, Proc.new {"rdoc"})
      action :template, "doc/%file_name%.rb.tt"
      file = File.join(destination_root, "doc/rdoc.rb")
      assert File.exists?(file)
    end

    it "logs status" do
      assert_equal "      create  doc/config.rb\n", capture(:stdout){ runner.template("doc/config.rb") }
    end

    it "accepts a block to change output" do
      action :template, "doc/config.rb" do |content|
        "OMG" + content
      end
      assert_match(/^OMG/, File.read(File.join(destination_root, "doc/config.rb")))
    end

    it "guesses the destination name when given only a source" do
      action :template, "doc/config.yaml.tt"

      file = File.join(destination_root, "doc/config.yaml")
      assert File.exists?(file)
    end
  end

  describe "when changing existent files" do

    def file
      File.join(destination_root, "doc", "README")
    end

    describe "#remove_file" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end
      
      it "removes the file given" do
        action :remove_file, "doc/README"
        refute File.exists?(file)
      end

      it "removes directories too" do
        action :remove_dir, "doc"
        refute File.exists?(File.join(destination_root, "doc"))
      end

      it "does not remove if pretending" do
        runner(:pretend => true)
        action :remove_file, "doc/README"
        assert File.exists?(file)
      end

      it "logs status" do
        assert_equal "      remove  doc/README\n", action(:remove_file, "doc/README")
      end

      it "does not log status if required" do
        assert action(:remove_file, "doc/README", :verbose => false).empty?
      end
    end

    describe "#gsub_file" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end
      
      it "replaces the content in the file" do
        action :gsub_file, "doc/README", "__start__", "START"
        assert_equal "START\nREADME\n__end__\n", File.binread(file)
      end

      it "does not replace if pretending" do
        runner(:pretend => true)
        action :gsub_file, "doc/README", "__start__", "START"
        assert_equal "__start__\nREADME\n__end__\n", File.binread(file)
      end

      it "accepts a block" do
        action(:gsub_file, "doc/README", "__start__"){ |match| match.gsub('__', '').upcase  }
        assert_equal "START\nREADME\n__end__\n", File.binread(file)
      end

      it "logs status" do
        assert_equal "        gsub  doc/README\n", action(:gsub_file, "doc/README", "__start__", "START")
      end

      it "does not log status if required" do
        assert action(:gsub_file, file, "__", :verbose => false){ |match| match * 2 }.empty?
      end
    end

    describe "#append_to_file" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end
      
      it "appends content to the file" do
        action :append_to_file, "doc/README", "END\n"
        assert_equal "__start__\nREADME\n__end__\nEND\n", File.binread(file)
      end

      it "accepts a block" do
        action(:append_to_file, "doc/README"){ "END\n" }
        assert_equal "__start__\nREADME\n__end__\nEND\n", File.binread(file)
      end

      it "logs status" do
        assert_equal "      append  doc/README\n", action(:append_to_file, "doc/README", "END")
      end
    end

    describe "#prepend_to_file" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end

      it "prepends content to the file" do
        action :prepend_to_file, "doc/README", "START\n"
        assert_equal "START\n__start__\nREADME\n__end__\n", File.binread(file)
      end

      it "accepts a block" do
        action(:prepend_to_file, "doc/README"){ "START\n" }
        assert_equal "START\n__start__\nREADME\n__end__\n", File.binread(file)
      end

      it "logs status" do
        assert_equal "     prepend  doc/README\n", action(:prepend_to_file, "doc/README", "START")
      end
    end

    describe "#inject_into_class" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end

      def file
        File.join(destination_root, "application.rb")
      end

      it "appends content to a class" do
        action :inject_into_class, "application.rb", Application, "  filter_parameters :password\n"
        assert_equal "class Application < Base\n  filter_parameters :password\nend\n", File.binread(file)
      end

      it "accepts a block" do
        action(:inject_into_class, "application.rb", Application){ "  filter_parameters :password\n" }
        assert_equal "class Application < Base\n  filter_parameters :password\nend\n", File.binread(file)
      end

      it "logs status" do
        assert_equal "      insert  application.rb\n", action(:inject_into_class, "application.rb", Application, "  filter_parameters :password\n")
      end

      it "does not append if class name does not match" do
        action :inject_into_class, "application.rb", "App", "  filter_parameters :password\n"
        assert_equal "class Application < Base\nend\n", File.binread(file)
      end
    end
  end

  describe "when adjusting comments" do

    def file
      File.join(destination_root, "doc", "COMMENTER")
    end

    unmodified_comments_file = /__start__\n # greenblue\n# yellowblue\n#yellowred\n #greenred\norange\n    purple\n  ind#igo\n  # ind#igo\n__end__/

    describe "#uncomment_lines" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end
      
      it "uncomments all matching lines in the file" do
        action :uncomment_lines, "doc/COMMENTER", "green"
        assert_match(/__start__\n greenblue\n# yellowblue\n#yellowred\n greenred\norange\n    purple\n  ind#igo\n  # ind#igo\n__end__/, File.binread(file))

        action :uncomment_lines, "doc/COMMENTER", "red"
        assert_match(/__start__\n greenblue\n# yellowblue\nyellowred\n greenred\norange\n    purple\n  ind#igo\n  # ind#igo\n__end__/, File.binread(file))
      end

      it "correctly uncomments lines with hashes in them" do
        action :uncomment_lines, "doc/COMMENTER", "ind#igo"
        assert_match(/__start__\n # greenblue\n# yellowblue\n#yellowred\n #greenred\norange\n    purple\n  ind#igo\n  ind#igo\n__end__/, File.binread(file))
      end

      it "does not modify already uncommented lines in the file" do
        action :uncomment_lines, "doc/COMMENTER", "orange"
        action :uncomment_lines, "doc/COMMENTER", "purple"
        assert_match(unmodified_comments_file, File.binread(file))
      end
    end

    describe "#comment_lines" do
      before do
        reset
        ::FileUtils.cp_r(source_root, destination_root)
      end

      it "comments lines which are not commented" do
        action :comment_lines, "doc/COMMENTER", "orange"
        assert_match(/__start__\n # greenblue\n# yellowblue\n#yellowred\n #greenred\n# orange\n    purple\n  ind#igo\n  # ind#igo\n__end__/, File.binread(file))

        action :comment_lines, "doc/COMMENTER", "purple"
        assert_match(/__start__\n # greenblue\n# yellowblue\n#yellowred\n #greenred\n# orange\n    # purple\n  ind#igo\n  # ind#igo\n__end__/, File.binread(file))
      end

      it "correctly comments lines with hashes in them" do
        action :comment_lines, "doc/COMMENTER", "ind#igo"
        assert_match(/__start__\n # greenblue\n# yellowblue\n#yellowred\n #greenred\norange\n    purple\n  # ind#igo\n  # ind#igo\n__end__/, File.binread(file))
      end

      it "does not modify already commented lines" do
        action :comment_lines, "doc/COMMENTER", "green"
        assert_match(unmodified_comments_file, File.binread(file))
      end
    end
  end
end
