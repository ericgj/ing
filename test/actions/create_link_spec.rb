require File.expand_path('../spec_helper', File.dirname(__FILE__))
require File.expand_path("../../lib/ing/files", File.dirname(__FILE__))

require 'tempfile'

describe Ing::Files::CreateLink do
  include SpecHelpers

  def reset
    @hardlink_to = File.join(Dir.tmpdir, 'linkdest.rb')
    ::FileUtils.rm_rf(destination_root)
    ::FileUtils.rm_rf(@hardlink_to)
  end

  def create_link(destination=nil, config={}, options={})
    @base = MyCounter.new(options)
    @base.destination_root = destination_root
    @base.call 1, 2
    MyCounter.send(:define_method, :file_name, Proc.new {'rdoc'} )

    @tempfile = Tempfile.new("config.rb")

    @action = Ing::Files::CreateLink.new(@base, destination, @tempfile.path,
                                            { :verbose => !@silence }.merge(config))
  end

  def invoke!
    capture(:stdout){ @action.invoke! }
  end

  def silence!
    @silence = true
  end

  describe "#invoke!" do
    before { reset }

    it "creates a symbolic link for :symbolic => true" do
      create_link("doc/config.rb", :symbolic => true)
      invoke!
      destination_path = File.join(destination_root, "doc/config.rb")
      assert File.exists?(destination_path)
      assert File.symlink?(destination_path)
    end

    it "creates a hard link for :symbolic => false" do
      create_link(@hardlink_to, :symbolic => false)
      invoke!
      destination_path = @hardlink_to
      assert File.exists?(destination_path)
      refute File.symlink?(destination_path)
    end

    it "creates a symbolic link by default" do
      create_link("doc/config.rb")
      invoke!
      destination_path = File.join(destination_root, "doc/config.rb")
      assert File.exists?(destination_path)
      assert File.symlink?(destination_path)
    end

    it "does not create a link if pretending" do
      create_link("doc/config.rb", {}, :pretend => true)
      invoke!
      refute File.exists?(File.join(destination_root, "doc/config.rb"))
    end

    it "shows created status to the user" do
      create_link("doc/config.rb")
      assert_equal "      create  doc/config.rb\n", invoke!
    end

    it "does not show any information if log status is false" do
      silence!
      create_link("doc/config.rb")
      assert invoke!.empty?
    end
  end

  describe "#identical?" do
    before { reset }
    
    it "returns true if the destination link exists and is identical" do
      create_link("doc/config.rb")
      refute @action.identical?
      invoke!
      assert @action.identical?
    end
  end
end
