﻿# Ing
## Vanilla ruby command-line scripting.

or gratuitous backronym: <b>I</b> <b>N</b>eed a <b>G</b>enerator! 

Ing is a task scripting micro-toolkit designed around the following opinions: 

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

- In particular, you want to be able to test your tasks independently of the
framework.

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

**NEW**: Ing now provides bash auto-completion (hooray!). Copy 
[the script](ing/blob/master/completions/ing.bash) to your OS' bash-completions directory, or source it manually, and tab away.

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

Note in most real cases you would want to namespace your tasks, and not use
a top-level class named Test (which would fail in some ruby versions in fact). 
This is just to give you a flavor.

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

## Standalone executables

You can use Ing to generate 'standalone' executables from your tasks, so you
can call it directly from the command line and also redistribute it (as a gem).
For more details see `ing help gemify`.

## Motivation

I wanted to use Thor's generator methods and shell conventions to write my own
generators. But I didn't want to fight against Thor's hijacking of ruby classes.

I love Rake, but find it much too easy to write horribly unmaintainable code in
its DSL, and always fight with its nonstandard command-line syntax.

## Q & A

### But what about task dependency resolution?

That's what `require` and `||=` are for ;)

Seriously, you do have `Ing.invoke Some::Task, :some_method` if you want a 
declarative way to say, from any point in your codebase, that you only want the
depended-on task to run only if it hasn't already. 

But before you do, please consider:

- If your case is _invoking a task only once within the same module_, you 
should probably simply design your methods so they are called that way in plain 
ruby.

- If your case is _running some bit of setup code_ that is shared among several 
tasks that would otherwise _not_ be executed as a task itself, `Ing.invoke` is
overkill. The code should be refactored so that it's accessible to the several
tasks, but not implemented as a task itself.

`Ing.invoke` is there for cases of multi-step tasks where you want access to
both the complete task and the sub-steps: such as mult-step compilation, the 
classic use-case for `make`.

In fact, if you find yourself needing to use `Ing.invoke` a lot, perhaps you 
should just use `make`, since the DSL is optimized for exactly this kind of 
task.

