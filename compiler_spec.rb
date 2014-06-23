$:<< File.join(File.dirname(__FILE__), '.')
require 'compiler'
require 'rspec'

  
describe 'Kaleidoscope.compile_run' do
  { '1+1' => 2.0,
    '-1+1' => 0.0,
    '1-1' => 0.0,
    '1*2' => 2.0,
    '-1*-2' => 2.0,
    '1/2' => 0.5,
    '2/1' => 2.0,
    '-2/-1' => 2.0,
    '0.5+0.5' => 1.0,
    '0.5-0.5' => 0.0,
    '2*0.5' => 1.0,
    '0.5/0.5' => 1.0,
    
    '2*3+2' => 8.0,
    '2+3*2' => 8.0,
    '(2+3)*2' => 10.0,
    '8/4/2' => 1.0,
    '1+4/2' => 3.0,

    '0<0' => 0.0,
    '0<1' => 1.0,
    '0>0' => 0.0,
    '0>1' => 0.0,
    '1<0' => 0.0,
    '1<1' => 0.0,
    '1>0' => 1.0,
    '1>1' => 0.0,
    
    "def f() 1
      f()" => 1.0,
    "def f(x) x
      f(2)" => 2.0,
    "def f(x) x
      f(1 + 2)" => 3.0,
    "def f(x, y) x + y
      f(2, 3)" => 5.0,
    "def f(x, y) x + y
      f(3 + 5, 5 + 8)" => 21.0,
    "def f(x) x + 1
      def g(x) x - 1
      f(g(1))" => 1.0,
    "def f(x) x
      def g(x) x / 2
      f(1) > g(1)" => 1.0,
    
    "def fac(n) if n > 1 then n * fac(n - 1) else 1
      fac(4)" => 24.0,
    
  }.each do |src, result|
    it(src) { Kaleidoscope.compile_run(src).should == result }
  end
end
