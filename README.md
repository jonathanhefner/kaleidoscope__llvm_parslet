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

Finally, run the tests:

```bash
$ LD_LIBRARY_PATH=/usr/lib/llvm-3.5/lib bundle exec rake test
```


## Usage

Compile and run a script using the `run` task:

```bash
$ LD_LIBRARY_PATH=/usr/lib/llvm-3.5/lib bundle exec rake run[path/to/script]
```

Try it with the scripts in the `examples` directory:

```bash
$ LD_LIBRARY_PATH=/usr/lib/llvm-3.5/lib bundle exec rake run[examples/factorial.kal]
39916800.0

$ LD_LIBRARY_PATH=/usr/lib/llvm-3.5/lib bundle exec rake run[examples/fibonacci.kal]
89.0
```

###### Contents of `examples/factorial.kal`:
```
def factorial(n)
  if n <= 1 then
    1
  else
    n * factorial(n - 1)


factorial(11)
```

###### Contents of `examples/fibonacci.kal`:
```
def fibonacci(n)
  if n <= 2 then
    1
  else
    fibonacci(n - 1) + fibonacci(n - 2)


fibonacci(11)
```
