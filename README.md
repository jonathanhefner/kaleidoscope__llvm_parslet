# Kaleidoscope

A simple programming language loosely following the 
[Kaleidoscope tutorial][].  Implemented in Ruby using [Parslet][] for 
parsing and [LLVM][] for JIT compilation.

  [kaleidoscope tutorial]: http://llvm.org/docs/tutorial/
  [parslet]: http://kschiess.github.io/parslet/
  [llvm]: http://llvm.org/


## Prerequisites

* Install Ruby and [Bundler](http://bundler.io/):

  ```bash
  sudo apt-get install ruby
  sudo gem install bundler
  ```

* Install LLVM 3.1 from source:

  ```bash
  wget http://llvm.org/releases/3.1/llvm-3.1.src.tar.gz

  tar -xzf llvm-3.1.src.tar.gz

  cd llvm-3.1.src

  # NOTE: skip docs because of incompatibility with current pod2man
  ./configure --enable-shared --enable-jit --disable-docs \
              --prefix=/usr/lib/llvm-3.1

  # This will take a while...
  make

  sudo make install
  ```


## Usage

```bash
cd /path/to/project

# Ensure llvm is in PATH while building native extensions
PATH="/usr/lib/llvm-3.1/bin:$PATH" bundle install

bundle exec rspec spec --format documentation
```
