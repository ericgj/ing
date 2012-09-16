# Ing
## Vanilla ruby command-line scripting.

or gratuitous backronym: <b>I</b> <b>N</b>eed a <b>G</b>enerator! 

Note this is a work-in-progress, not quite ready for use.

The command-line syntax is similar to Thor's, and it incorporates Thor's 
(Rails') generator methods and shell conventions like

```ruby
if yes? 'process foo files?', :yellow
  inside('foo') { create_file '%foo_file%.rb' }
end
``` 
but _unlike_ Thor or Rake, it does not define its own DSL. Your tasks correspond 
to plain ruby classes and methods. Ing just handles routing from the command line 
to them, and setting options. Your classes (or even Procs) do the rest.

Option parsing courtesy of the venerable and excellent
[Trollop](http://trollop.rubyforge.org/), under the hood.

## Installation

_Note: not yet gemified_

    gem install ing
    
## A quick tour

### The command line

The ing command line is generally parsed as 

    [ing command] [ing command options] [subcommand] [args] [subcommand options]
    
But in cases where the first argument isn't an built-in ing command or options, it's 
simplified to

    [subcommand] [args] [subcommand options]

The "subcommand" is your task. To take some examples.

    ing -r./path/to/some/task.rb some:task run something --verbose
    
  1. `ing -r` loads specified ruby files or libraries/gems; then
  2. it dispatches to `Some::Task.new(:verbose => true).run("something")`.

(Assuming you define a task `Some::Task#run`, in `/path/to/some/task.rb`.)

You can -r as many libaries/files as you like. Of course, that gets pretty 
long-winded. 

By default, it requires a file `./ing.rb` if it exists (the equivalent of 
Rakefile or Thorfile). In which case, assuming your task class is
defined or loaded from there, the command can be simply 

    ing some:task run --verbose

### Built-in commands

Ing has some built-in commands. These are still being implemented, but
you can see what they are so far with `ing list`.

The most significant subcommand is `generate` or `g`, which
simplifies a common and familiar use-case (at the expense of some file-
system conventions):

    ing generate some:task --force

Unlike Thor/Rails generators, these don't need to be packaged up as gems
and preloaded into ruby. They can be either parsed as:

  1. A __file__ relative to a root dir: e.g. __some/task__, or
  2. A __subdirectory__ of the root dir, in which case it attempts to
  preload `ing.rb` within that subdirectory: e.g. __some/task/ing.rb__

The command above is then dispatched as normal to 
`Some::Task.new(:force => true).call`  (`#call` is used if no method is
specified). So you should put the task code within that namespace in the
preloaded file.

(By default, the generator root directory is specified by 
`ENV['ING_GENERATORS_ROOT']` or failing that, `~/.ing/generators`.)

_TODO: more examples needed_

### A simple example of a plain old ruby task

Let's say you want to run your project's tests with a command like `ing test`.
The default is to run the whole suite; but if you just want unit tests you can
say `ing test unit`. This is what it would look like (in `./ing.rb`):

```ruby
class Test

  # no options passed, but you need the constructor
  def initialize(options); end
  
  # `ing test`
  def call(*args)
    suite
  end
  
  # `ing test suite`
  def suite
    unit; functional; acceptance
  end

  # `ing test unit`
  def unit
    type 'unit'
  end

  # `ing test functional`
  def functional
    type 'functional'
  end

  # `ing test acceptance`
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
you can also do `ing test type unit`: extra non-option arguments are passed into 
the method as parameters.  

For more worked examples of ing tasks, see the 
[examples](ing/blob/master/examples) directory.

[MORE](ing/blob/master/TASKS.md)

### Option arguments

Your tasks (ing subcommands) can specify what options they take by defining a 
class method `specify_options`.  The best way to understand how this is done is 
by example:

```ruby
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
```

The syntax used in `self.specify_options` is Trollop - in fact what you are 
doing is building a `Trollop::Parser` which then emits the parsed options into 
your constructor. In general your constructor should just save the options to
an instance variable like this, but in some cases you might want to do further
processing of the passed options.

[MORE](ing/blob/master/OPTIONS.md)

### Generator tasks

If you want to use Thor-ish generator methods, your task classes need a few more
things added to their interface. Basically, it should look something like this.

```ruby
class MyGenerator

  def self.specify_options(expect)
    # ...
  end
  
  include Ing::Files
  
  attr_accessor :destination_root, :source_root, :options, :shell
  
  # default == execution from within your project directory
  def destination_root
    @destination_root ||= Dir.pwd
  end
  
  # default == current file is within root directory of generator files
  def source_root
    @source_root ||= File.expand_path(File.dirname(__FILE__))
  end
  
  def initialize(options)
    self.options = options
  end
  
  # ...
end
```

The generator methods need `:destination_root`, `:source_root`, and `:shell`.
Also, `include Ing::Files` _after_ you specify any options (this is because
`Ing::Files` adds several options automatically).

[MORE](ing/blob/master/GENERATORS.md)

## Motivation

I wanted to use Thor's generator methods and shell conventions to write my own
generators. But I didn't want to fight against Thor's hijacking of ruby classes.

### Brief note about the design

One of the design principles is to limit inheritance (classical and mixin), and
most importantly to _avoid introducing new state via inheritance_. An important
corollary of this is that the _application objects_, ie. your task classes, 
must themselves take responsibility for their interface with the underlying
resources they mix in or compose, instead of those resources providing the 
interface (via so-called macro-style class methods, for instance).

## Q & A

### But what about task dependency resolution?

That's what `require` and `||=` are for ;)

Seriously, you do have `Ing.invoke Some::Task, :some_method` and `Ing.execute ...`
for this kind of thing. Personally I think it's a code smell to put reusable
code in things that are _also_ run from the command line. Is it application or
library code? Controller or model? But `invoke` is there if you must, hopefully 
with a suitably ugly syntax to dissuade you. :P

### But what about security?

Yes, this means any ruby library and even built-in classes can be exercised from
the command line... but so what?

1. You can't run module methods, and the objects you invoke need to have a
hash constructor. So Kernel, Process, IO, File, etc. are pretty much ruled out.
Most of the ruby built-in classes are ruled out in fact.

2. More to the point, you're already in a shell with much more dangerous knives
lying around. You had better trust the scripts you're working with!

