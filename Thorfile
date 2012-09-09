require File.expand_path('lib/thor/shell/basic', File.dirname(__FILE__))
require File.expand_path('lib/thor/actions/file_manipulation', File.dirname(__FILE__))

class Generate < Thor::Group
  
  argument :name
  class_option :base_dir, :default => ENV['GENERATORS_BASE_DIR']
  
  def load
    base = options[:base_dir] || 
           ask('Where do you want to look for generator templates?')
    file = File.expand_path("#{base}/#{name}/Thorfile", Dir.pwd)
    say "Loading #{file}", :yellow
    Kernel.load file
    say "Loaded", :green
  end
  
  def execute
    say "Executing #{name}:generate", :yellow
    invoke "#{name}:generate"
    say "Finished #{name}:generate", :green
  end
  
end