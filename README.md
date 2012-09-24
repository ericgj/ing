# Ing
## Vanilla ruby command-line scripting.

or gratuitous backronym: <b>I</b> <b>N</b>eed a <b>G</b>enerator! 

Ing is a scripting and command-line API micro-toolkit designed around the 
following opinions: 

- Ruby itself is a domain-specific language for scripting (among other things), 
it has great facilities for dealing with filesystems, processes, network IO, 
interacting with the shell, etc;

- In addition, Ruby's object model gives you most of what you need for 
organizing your code into tasks to be run from the command line, for dependency 
management, handling errors, etc.

- Sometimes the functionality your tasks implement you want to make use of 
within other programs, not only from the shell. You don't want to have to 
either (a) wade through the scripting framework to figure out how to get to it, 
or (b) refactor your tasks into separate modules and classes.

- A framework (any framework, in any context) should not encourage bad design 
at the expense of supposed simplicity of the interface. A framework should 
get out of the way as much as possible.

## Introduction

The core of what Ing provides is a _router_ and built-in _option parser_ (using 
the venerable and excellent [Trollop](http://trollop.rubyforge.org/)) that maps 
the command line to your ruby classes and methods, using simple conventions.

For example, this:

```bash
ing some:task run something --verbose
```

in the most typical scenario, routes to:

```ruby
Some::Task.new(:verbose => true).run("something")
```

or if Some::Task is not a class but a proc or other 'callable', routes to:

```ruby
Some::Task.call(:run, "something", :verbose => true)
```

As you can see, although the implementation is completely different, the 
command-line syntax is similar to Thor's. 

In addition, Ing includes Thor's (Rails') generator methods and conventions 
so you can do things like this within your tasks:

```ruby
if yes? 'process foo files?', :yellow
  inside('foo') { create_file '%foo_file%.rb' }
end
``` 

Unlike Thor or Rake, Ing does not define its own DSL. Your tasks correspond 
to plain ruby objects and methods. Ing just handles routing from the command 
line to them, and setting options. Your classes or procs do the rest.

As we will see, there are some base classes your tasks can inherit from that 
cut down on boilerplate code for common scenarios, but they are there only for 
convenience: your task classes/procs are not required to be coupled to the 
framework at all.

[MORE](ing/blob/master/SYNTAX.md)

## Installation

    gem install ing
    
To generate a default `ing.rb` file (similar to Rakefile or Thorfile), that 
loads from a `tasks` directory:
    
    ing setup
    
## Usage

### Built-in commands

Ing has some built-in commands. You can see what they are (so far) with 
`ing list -n ing:commands`.  And you can get help on a command with 
`ing help ...`.

### Generator tasks

The most significant built-in Ing command is `generate` or `g`, which
simplifies a common and familiar use-case (at the expense of some file-
system conventions):

    ing generate some:task --force

Unlike Thor/Rails generators, these don't need to be packaged up as gems
and preloaded into ruby. They can be parsed as either:

  1. A __file__ relative to a root dir: e.g. __some/task__, or
  2. A __subdirectory__ of the root dir, in which case it attempts to
  preload `ing.rb` within that subdirectory: e.g. __some/task/ing.rb__

So the command above is then dispatched as normal to 
`Some::Task.new(:force => true).call`  (`#call` is used if no method is
specified). So you should put the task code within that namespace in the
preloaded file.

(By default, the generator root directory is specified by 
`ENV['ING_GENERATORS_ROOT']` or failing that, `~/.ing/generators`.)

[MORE](#)

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
you can also do `ing test type custom`: extra non-option arguments are passed 
into the method as parameters.  

For more worked examples of ing tasks, see the 
[examples](ing/blob/master/examples) directory.

[MORE](ing/blob/master/TASKS.md)

### Option arguments

Your tasks (ing subcommands) can specify what options they take by defining a 
class method `specify_options`.  For example:

```ruby
class Cleanup

  def self.specify_options(spec)
    spec.text "Clean up your path"
    spec.text "\nUsage:"
    spec.text "ing cleanup [OPTIONS]"
    spec.text "\nOptions:"
    spec.opt :quiet, "Run silently"
    spec.opt :path,  "Path to clean up", :type => :string, :default => '.'
  end
    
  attr_accessor :options
  
  def initialize(options)
    self.options = options
  end
  
  # ...
end
```

The syntax used in `self.specify_options` is Trollop - in fact what you are 
doing is building a `Trollop::Parser` which then sends the parsed options into 
your constructor. 

In general your constructor should just save the options to
an instance variable like this, but in some cases you might want to do further
processing of the passed options.

[MORE](ing/blob/master/OPTIONS.md)

### Using the Ing::Task base class

To save some boilerplate, and to allow more flexible options specification, 
as well as a few more conveniences, you can inherit from `Ing::Task` and 
rewrite this example as:

```ruby
class Cleanup < Ing::Task
  desc "Clean up your path"
  usage "ing cleanup [OPTIONS]"
  opt :quiet, "Run silently"
  opt :path,  "Path to clean up", :type => :string, :default => '.'

  # ...
end
```

This gives you a slightly more automated help message, with the description
lines followed by usage followed by options, and with headers for each section.

`Ing::Task` also lets you inherit options. Say you have another task:

```ruby
class BigCleanup < Cleanup
  opt :servers, "On servers", :type => :string, :multi => true
end
```

This task will have the two options from its superclass as well as its own. 
(Note the description and usage lines are _not_ inherited this way, only the 
options).

### Generator tasks

If you want to use Thor-ish generator methods, your task classes need a few more
things added to their interface. Basically, it should look something like this.

```ruby
class MyGenerator

  def self.specify_options(spec)
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

If you prefer, you can inherit from `Ing::Generator`, which gives you all of 
the above defaults more or less, plus the functionality of `Ing::Task`.

Like `Ing::Task`, `Ing::Generator` is simply a convenience for common scenarios.

[MORE](ing/blob/master/GENERATORS.md)

## Motivation

I wanted to use Thor's generator methods and shell conventions to write my own
generators. But I didn't want to fight against Thor's hijacking of ruby classes.

I love Rake, but find it much too easy to write horribly unmaintainable code in
its DSL, and always fight with its nonstandard command-line syntax.

## Q & A

### But what about task dependency resolution?

That's what `require` and `||=` are for ;)

Seriously, you do have `Ing.invoke Some::Task, :some_method` for this kind of 
thing. Personally I think it's a code smell to put reusable code in things that 
are _also_ run from the command line. Is it application or library code? 
Controller or model? But `invoke` is there if you must, hopefully with a 
suitably ugly syntax to dissuade you. :P

### But what about security?

Yes, this means any ruby library and even built-in classes can be exercised from
the command line... but so what?

1. You can't run module methods, and the objects you invoke need to have a
hash constructor. So Kernel, Process, IO, File, etc. are pretty much ruled out.
Most of the ruby built-in classes are ruled out in fact.

2. More to the point, you're already in a shell with much more dangerous knives
lying around. You had better trust the scripts you're working with!

