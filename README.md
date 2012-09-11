# Ing
## Vanilla ruby command-line scripting.

or gratuitous backronym: <b>I</b> <b>N</b>eed a <b>G</b>enerator! 

Note this is a work-in-progress, not quite ready for use.

The command-line syntax is similar to Thor's, and it incorporates Thor's 
(Rails') generator methods and shell conventions like

```ruby
if yes? 'process foo files?', :yellow
  inside 'foo' { create_file %foo_file%.rb }
end
```
but unlike Thor or Rake, it does not define its own DSL. Your tasks correspond 
to PORO classes and methods. Ing just handles routing from the command line to 
them, and setting options. Your classes (or even Procs) do the rest.

Option parsing courtesy of the venerable and excellent
[Trollop](http://trollop.rubyforge.org/), under the hood.

## Installation

    gem install ing
    
## A quick tour

### The command line

The ing command line is generally parsed as 

    [ing command] [ing command options] [subcommand] [args] [subcommand options]
    
But in cases where the first argument isn't an ing command or options, it's 
simplified to

    [subcommand] [args] [subcommand options]

To take some examples.

    ing -r./path/to/some/task.rb some:task run --verbose
    
  1. `ing -r` loads specified ruby files or libraries/gems; then
  2. it dispatches to `Some::Task.new(:verbose => true).run`.

(Assuming you define a task `Some::Task#run`, in `/path/to/some/task.rb`.)

You can -r as many libaries/files as you like. Of course, that gets pretty 
long-winded. By default, it requires a file `./ing.rb` if it exists (the 
equivalent of Rakefile or Thorfile).

Ing has some built in helper commands, notably `generate` or `g`, which
simplifies a common and familiar use-case (at the expense of some file-
system conventions):

    ing generate some:task --force

Unlike Thor/Rails generators, these don't need to be packaged up as gems
and preloaded into ruby. They can be either parsed as:

  1. A __file__ relative to a root dir (by default, `ENV['ING_GENERATORS_ROOT']` or
  `~/.ing/generators`): e.g. __some/task__, or
  2. A __subdirectory__ of the root dir, in which case it attempts to
  preload `ing.rb` within that subdirectory: e.g. __some/task/ing.rb__

The command is then dispatched as normal to 
`Some::Task.new(:force => true).call`  (`#call` is used if no method is
specified). So you should put the task code within that namespace in the
preloaded file.

_TODO: more examples needed_

### A simple example of a plain old ruby task

Let's say you want to run your project's tests with a command like `ing test`.
The default is to run the whole suite; but if you just want unit tests you can
say `ing test unit`. This is what it would look like (in `./ing.rb`):

```ruby
class Test

  # no options passed, but you need the constructor
  def initialize(options); end
  
  def call(*args)
    suite
  end
  
  def suite
    unit; functional; acceptance
  end

  def unit
    type 'unit'
  end

  def functional
    type 'functional'
  end

  def acceptance
    type 'acceptance'
  end
  
  def type(dir)
    Dir["./test/#{dir}/*.rb"].each { |f| require_relative f }
  end
  
end
```
    
As you can see, the second arg corresponds to the method name. `call` is what
gets called when there is no second arg.  Organizing the methods like this means
you can also do `ing test type unit`: extra args are passed into the method as
parameters.  See [MORE](TASKS.md)

### Option arguments

Your tasks (ing subcommands) can specify what options they take by defining a 
class method `specify_options`.  The best way to understand how this is done is 
by example:

    class Cleanup
    
      def self.specify_options(expect)
        expect.opt :quiet, "Run silently"
        expect.opt :path,  "Path to clean up", :type => :string, :default => '.'
      end
      
      attr_accessor :options
      
      def initialize(options)
        self.options = options
      end
      
      # ...
    end

The syntax used in `self.specify_options` is Trollop - in fact what you are 
doing is building a `Trollop::Parser` which then emits the parsed options into 
your constructor. In general your constructor should just save the options to
an instance variable like this, but in some cases you might want to do further
processing of the passed options.

See [MORE](OPTIONS.md)

### Generator tasks

If you want to use Thor-ish generator methods, your task classes need a few more
things added to their interface. Basically, it should look something like this.

    class MyGenerator
    
      def self.specify_options(expect)
        # ...
      end
      
      include Ing::Files
      
      attr_accessor :destination_root, :source_root, :options, :shell
      def destination_root
        @destination_root ||= Dir.pwd
      end
      
      def initialize(options)
        self.options = options
      end
      
      # ...
    end

The generator methods need `:destination_root`, `:source_root`, and `:shell`.
Also, `include Ing::Files` _after_ you specify any options (this is because
`Ing::Files` adds several options automatically).

See [MORE](GENERATORS.md)

## Motivation

I wanted to use Thor's generator methods and shell conventions to write my own
generators. But I didn't want to fight against Thor's hijacking of ruby classes.

### But what about task dependency resolution?

That's what `require` is for ;)
