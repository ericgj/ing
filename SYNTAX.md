## A quick tour of Ing command-line syntax

The ing command line is generally parsed as 

    [ing command] [ing command options] [subcommand] [args] [subcommand options]
    
But in cases where the first argument isn't a built-in ing command or options, 
it's simplified to

    [subcommand] [args] [subcommand options]

The "subcommand" is your task. To take some examples.

    ing -r ./path/to/some/task.rb some:task run something --verbose
    
  1. `ing -r` loads specified ruby files or libraries/gems; then
  2. it dispatches to `Some::Task.new(:verbose => true).run("something")`.

(Assuming you define a task `Some::Task#run`, in `/path/to/some/task.rb`.)

You can -r as many libaries/files as you like. Of course, that gets pretty 
long-winded. 

By default, it requires a file `./ing.rb` if it exists (the equivalent of 
Rakefile or Thorfile). In which case, assuming your task class is
defined or loaded from there, the command can be simply 

    ing some:task run something --verbose
    
