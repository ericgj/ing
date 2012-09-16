# Usage:
# ing rspec:convert    which is equivalent to
# ing rspec:convert files './{test,spec}/**/*.rb' --convert-dir 'converted'
#
module Rspec

  class Convert
    
    GSUBS = \
    [ 
      [ /^(\s*)(.+)\.should\s+be_true/          , '\1assert \2'            ],
      [ /^(\s*)(.+)\.should\s+be_false/         , '\1refute \2'            ],
      [ /^(\s*)(.+)\.should\s*==\s*(.+)$/       , '\1assert_equal \3, \2'  ],
      [ /^(\s*)(.+)\.should_not\s*==\s*(.+)$/   , '\1refute_equal \3, \2'  ],
      [ /^(\s*)(.+)\.should\s*=~\s*(.+)$/       , '\1assert_match(\3, \2)' ],
      [ /^(\s*)(.+)\.should_not\s*=~\s*(.+)$/   , '\1refute_match(\3, \2)' ],
      [ /^(\s*)(.+)\.should\s+be_(.+)$/         , '\1assert \2.\3?'        ],
      [ /^(\s*)(.+)\.should_not\s+be_(.+)$/     , '\1refute \2.\3?'        ],
      [ /expect\s+\{(.+)\}\.to\s+raise_error\s*\((.*)\)\s*\Z/m, 
        'assert_raises(\2) {\1}'                                      ],
      [ /\{(.+)\}\.should raise_error\s*\((.*)\)\s*\Z/m,
        'assert_raises(\2) {\1}'                                        ],
    # these next aren't quite right because they need to wrap the next 
    # lines as a lambda. Thus the FIXME notes.
      [ /\.should_receive\(([^\)]+)\)\.and_return\((.+)\)/,  
        '.stub(\1, \2) do |s|  # FIXME'                                 ],
      [ /.stub\!\(([\w:]+)\)\.and_return\((.+)\)/,
        '.stub(\1, \2) do |s|  # FIXME'                                 ]
      
    ]
    
    def self.specify_options(expect)
      expect.opt :pattern, "Directory glob pattern for test files",
                 :type => :string, :default => './{test,spec}/**/*.rb'
      expect.opt :convert_dir, "Subdirectory to save converted files",
                 :type => :string, :default => 'converted'
      expect.banner "Convert rspec should/not matchers to minitest assert/refute"
      expect.text "It's not magic, you still need to hand edit your test files after running this"
    end
    
    include Ing::Files
    
    attr_accessor :shell, :options, :destination_root, :source_root
    
    def destination_root; @destination_root ||= Dir.pwd; end
    def source_root;      @source_root ||= File.dirname(__FILE__); end
    
    def input_files
      @input_files ||= Dir[ File.expand_path(options[:pattern], source_root) ]
    end
    
    def converted_files
      input_files.map {|f|
        File.join( File.dirname(f), options[:convert_dir], File.basename(f) )
      }
    end
    
    def conversion_map
      input_files.zip(converted_files)
    end
    
    def initialize(options)
      self.options = options
    end
    
    def call(pattern=nil)
      options[:pattern] = pattern || options[:pattern]
      shell.say "Processing #{input_files.length} input files: #{options[:pattern]}" if verbose?
      conversion_map.each do |input_f, output_f|
        new_lines = convert_lines(input_f)
        create_file output_f, new_lines.join
      end
    end
    alias :files :call
    
    private
    
    def convert_lines(fname)
      count = 0; accum = []
      File.open(fname) do |f|
        f.each_line do |line|
          new_line = GSUBS.inject(line) do |str, (rx, replace)|
            str = str.gsub(rx, replace)
          end
          count += 1 if line != new_line
          accum << new_line
        end
      end
      shell.say_status(:convert, 
                       "#{relative_to_original_destination_root(fname)}: " +
                         "#{count} changes", 
                       :green) if verbose?
      accum
    end
        
  end
  
end