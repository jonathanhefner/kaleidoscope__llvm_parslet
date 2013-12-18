# Kaleidoscope

An implementation of a *very simple* programming language, loosely following 
the [LLVM/Kaleidoscope tutorials](http://llvm.org/docs/tutorial). 
[Parslet](https://github.com/kschiess/parslet) is used for parsing, and 
[ruby-llvm](https://github.com/ruby-llvm/ruby-llvm) is used for JIT compilation.


## Installation

The current environment I'm working in (cygwin) only has LLVM 3.1, so I've 
constrained the ruby-llvm gem to a version which supports that.  If you have a 
newer version of LLVM, simply change the Gemfile to reflect that (the ruby-llvm 
gem major and minor revision numbers match that of LLVM).

After that, a simple `bundle install` should be sufficient (assuming you've 
already installed [Bundler](http://bundler.io)).


## Usage

Create a file containing Kaleidoscope code, say factorial.kal:

    def fac(n)
      if n > 1 then 
        n * fac(n - 1)
      else
        1
        
    fac(10)

Then feed that to the runner script, kal.rb:

    $ cat factorial.kal | ruby kal.rb

or 

    $ ruby kal.rb factorial.kal
