require 'optparse'

module Gin
  
  class Parser
  
    def initialize(argv)
      @argv = argv.dup
      @options = {}
      option_parser.parse!(@argv)
    end
    
    def parsed
      @parsed ||= 
        [ to_classes(@argv.shift), to_meth(@argv.shift), @argv, @options]
    end
    
    def option_parser
      OptionParser.new do |p|
        p.on("-v", "--[no-]verbose", "Run verbosely by default") do |v|
          @options[:verbose] = v
        end
        
        p.on("-f", "--[no-]force", "Overwrite files that already exist") do |v|
          @options[:force] = v
        end
        
        p.on("-p", "--[no-]pretend", "Run but do not make any changes") do |v|
          @options[:pretend] = v
        end
        
        p.on("-q", "--[no-]quiet", "Suppress status output") do |v|
          @options[:quiet] = v
        end
        
        p.on("-s", "--[no-]skip", "Skip files that already exist") do |v|
          @options[:skip] = v
        end
      end
    end
    
    def to_classes(str)
      str.split(':').map {|c| c.gsub!(/(?:\A|_+)(\w)/) {$1.upcase} }
    end
    
    def to_meth(str)
      str.downcase if str
    end
    
  end

end