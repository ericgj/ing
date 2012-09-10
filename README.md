# Ing
## Vanilla ruby command-line scripting.

or gratuitous backronym:
### _I_ _N_ eed a _G_ enerator! 

Note this is a work-in-progress, not quite ready for use.

The command-line syntax is similar to Thor's, and it incorporates Thor's 
(Rails') generator methods (`inside 'foo' { create_file %foo_file%.rb }`) and
shell conventions (`yes? 'process foo files?', :yellow`), but unlike Thor or
Rake, does not define its own DSL. Your tasks correspond to PORO classes and methods. Ing just handles routing from the command line to them, and setting
options. Your classes (or even Procs) do the rest.

Option parsing courtesy of the venerable and excellent
[Trollop](http://trollop.rubyforge.org/), under the hood.

## Installation

    gem install ing
    
## Command line usage
    
Say you define a task `Some::Task#run`, at `/path/to/some/task.rb`.

    ing -r./path/to/some/task.rb some:task run --verbose
    
To walk through that command a bit: 

  1. `ing -r` loads specified ruby files or libraries/gems; then
  2. it dispatches to `Some::Task.new(:verbose => true).run`.

You can -r as many libaries/files as you like. Of course, that gets pretty 
long-winded.

Ing has some built in helper commands, notably `generate` or `g`, which
simplifies a common use-case (at the expense of some file-system conventions):

    ing generate some:task --force

Unlike Thor/Rails generators, these don't need to be packaged up as gems
and preloaded into ruby. They can be either parsed as:

  1. A __file__ relative to a root dir (`ENV['ING_GENERATORS_ROOT']` or
  `~/.ing/generators`): e.g. __some/task__, or
  2. A __subdirectory__ of the root dir, in which case it attempts to
  preload `ing.rb` within that subdirectory: e.g. __some/task/ing.rb__

The command is then dispatched as normal to 
`Some::Task.new(:force => true).call`  (`#call` is used if no method is
specified). So you should put the task code within that namespace in the
preloaded file.

_TODO: more examples needed_

## Tasks, in plain old ruby

_TODO_


## Motivation

I wanted to use Thor's generator methods and shell conventions to write my own
generators. But I didn't want to fight against Thor's hijacking of ruby classes.

### But what about task dependency resolution?

That's what `require` is for ;)
