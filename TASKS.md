### More about Tasks

Incidentally, there's nothing stopping you from implementing the "Test" example 
functionally. It could look (simplifying a little) like this:

    Test = lambda {|arg| 
      type = lambda {|*dirs|
        dirs.each do |dir|
          Dir["./test/#{dir}/*.rb"].each { |f| require_relative f }
        end
      }
      suite = lambda { type['unit','functional','acceptance'] }
      arg ? type[arg] : suite[]
    }

Ing can either invoke class instance methods (on things that respond to `new`), 
or call Procs directly. The advantage of using classes is that some of the
argument parsing is done for you (especially true of option arguments as we'll 
see in a minute). You can use methods to basically model the command line 
syntax. The advantage of Procs is you have more flexibility in how arguments
are interpreted.