module Ing

	# A base class for unix-y filters
	# Note subclasses should implement +filter+, not +call+
	#
	# Similar to ARGF, it abstracts whether input is from $stdin or ARGV files
	# However, it allows processing one file at a time (via +each+) rather than 
	# exposing a file stream of the concatenated files.
	#
	# Output is $stdout unless --dest is specified. In a typical case, --dest
	# is used to specify a directory where processed files are copied to 1-to-1.
	# This is the intent of the helper method +output_file+. But you can of course
	# output using whatever scheme you like. 
	#
	# The +write_to+ method abstracts whether output is directed to $stdout or to 
	# files. Note that with --quiet option specified and output directed to files,
	# the names of the files are output to $stdout. This is so that the filter
	# can be chained (via xargs -d "\n") even when writing to files rather than
	# $stdout. You should also pass the --force option in this case to avoid 
	# warning messages mangling the output.
	#
	class Filter < Ing::Generator
		
		include Enumerable
		
		def stdout?
			!options[:dest_given]
		end
		
		attr_accessor :args
		
		def initial_options(given)
			given[:dest]   ||= Dir.pwd
			given[:source] ||= given[:dest]
			self.options = given
		end
				
		def call(*args)
			self.args = args
			filter
		end
		
		# Implement in subclass
		def filter
		end
		
		# Mimicks ARGF, except multiple input files are yielded one at a time
		# together with path names. 
		#
		def each
			if args.empty?
				yield $stdin, "-"
			else
				args.each do |arg|
					File.open(arg, 'r') do |f|
						yield f, arg
					end
				end
			end
		end
		alias each_input each
		
		# Returns +input_file+ relative to destination_root, optionally with different 
		# file extension. Returns nil if no destination (output to stdout).
		#
		def output_file(input_file, ext=nil)
			return if stdout?
			basename = ext ? File.basename(input_file).gsub(/\..+$/,ext) :
			                 File.basename(input_file)
			File.expand_path(basename, destination_root)
		end
		
		# Write yielded +block+, or +strings+, to +output_file+.
		# If output_file is nil, write to stdout instead.
		#
		def write_to(output_file, *strings, &block)
			data = block_given? ? yield : strings.join($\)
			if output_file
				create_file output_file, data
				$stdout.puts output_file if quiet?
			else
				$stdout.write data
			end
		end
		
	end
	
end

__END__

# save this for tests...

class GroovyConcat < Ing::Filter

	desc "A groovy concat filter"
	
	def filter
		each do |f, path|
			write_to output_file(path), 
			      "\n~~~~~~~~~ #{path}\n", 
						f.read
		end
	end

end