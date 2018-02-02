# Kaleidoscope

A simple programming language loosely following the
[Kaleidoscope tutorial][].  Implemented in Ruby using [Parslet][] for
parsing and [LLVM][] for JIT compilation.

  [kaleidoscope tutorial]: http://llvm.org/docs/tutorial/
  [parslet]: http://kschiess.github.io/parslet/
  [llvm]: http://llvm.org/


## Installation

First, install LLVM 3.5 from source (this requires Python 2):

```bash
$ wget -qO- http://llvm.org/releases/3.5.2/llvm-3.5.2.src.tar.xz | tar -xJ

$ cd llvm-3.5.2.src

$ ./configure --enable-shared --enable-jit --prefix=/usr/lib/llvm-3.5

# This will take a while...
$ make

$ sudo make install
```

Next, run `bundle install` with a pointer to LLVM:

```bash
$ cd /path/to/kaleidoscope

$ LLVM_CONFIG=/usr/lib/llvm-3.5/bin/llvm-config bundle install
```


## Usage

Run the tests:

```bash
$ LD_LIBRARY_PATH=/usr/lib/llvm-3.5/lib bundle exec rspec spec --format documentation
```
