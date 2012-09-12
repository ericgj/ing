# Ing
## _I_ _N_eed a _G_enerator! 

Vanilla ruby command-line scripting. The command-line syntax is similar to 
Thor's, and it incorporates Thor's (Rails') generator methods 
(`inside 'foo' { create_file %foo_file%.rb }`) and shell conventions
(`yes? 'process foo files?', :yellow`), but unlike Thor or Rake does not define
its own DSL. Your tasks correspond to PORO methods, Ing just handles dispatching
from the command line to them and setting options.

## Installation

    gem install ing
    
## Usage
    
Say you define a task `Some::Task#run`, at /path/to/some/task.rb.

    ing -r./path/to/some/task.rb some:task run --verbose
    
To parse that command a bit: 

1. `ing -r` loads specified ruby files or libraries; then
2. it dispatches to `Some::Task.new(:verbose => true).run`.

Ing has some built in helper commands, notably `generate` or `g`, which
simplifies a common use-case (at the expense of some file-system conventions):

    ing generate some:task --force

Unlike Thor/Rails generators, these don't need to be packaged up as gems
and preloaded into ruby. They can be either parsed as:

1. A file relative to the _generators root dir_ (`ENV['ING_GENERATORS_ROOT']` or
`~/.ing/generators`), e.g. some/task, or
2. A subdirectory of the generators root dir, in which case it attempts to
preload `ing.rb` within that subdirectory, e.g. some/task/ing.rb

The command is then dispatched as normal to 
`Some::Task.new(:force => true).call`  (#call is used if no method is
specified). So you should put the task code within that namespace in the
preloaded file.

_TODO: more examples needed_

## Motivation



### But what about task dependency resolution?

That's what `require` is for.
