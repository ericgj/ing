require File.expand_path("lib/ing/version", File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name        = "ing"
  s.version     = Ing::VERSION
  s.authors     = ["Eric Gjertsen"]
  s.email       = ["ericgj72@gmail.com"]
  s.homepage    = "https://github.com/ericgj/ing"
  s.summary     = %q{Vanilla ruby command-line scripting}
  s.description = %q{
An alternative to Rake and Thor, Ing has a command-line syntax similar to 
Thor's, and it incorporates Thor's (Rails') generator methods and shell 
conventions. But unlike Thor or Rake, it does not define its own DSL. Your tasks
correspond to plain ruby classes and methods. Ing just handles routing from the 
command line to them, and setting options. Your classes (or even Procs) do the 
rest.
  }

  s.rubyforge_project = ""

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ["lib"]
  s.executables   << 'ing'
  
  s.requirements << "ruby >= 1.9"
    
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'fakeweb'
  
end