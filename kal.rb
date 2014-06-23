require 'parser'
require 'compiler'

puts Kaleidoscope.compile_run($<.read)
