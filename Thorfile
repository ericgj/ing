require File.expand_path('lib/thor/shell/basic', File.dirname(__FILE__))
require File.expand_path('lib/thor/actions/file_manipulation', File.dirname(__FILE__))

class Generate < Thor::Group
  include Thor::Actions
  
  argument :name
  class_option :base_dir, :default => ENV['GENERATORS_BASE_DIR']
  add_runtime_options!
  
  def load
    base = options[:base_dir] || 
           ask('Where do you want to look for generator templates?')
    file = File.expand_path("#{base}/#{name}/Thorfile", Dir.pwd)
    say "Loading #{file}", :yellow
    Kernel.load file
  end
  
  def execute
    say "Executing #{name}:generate with options #{self.options.inspect}", :yellow
    invoke "#{name}:generate", [], self.options
    say "Finished #{name}:generate", :green
  end
  
end