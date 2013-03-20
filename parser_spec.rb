require './parser.rb'
require 'rspec'
require 'parslet/rig/rspec'


describe Kaleidoscope::Parser do
  KEYWORDS = %w[def if then else]
  BINARY_OPS = %w[< > + - * /]
  UNARY_OPS = %w[+ -]

  subject(:parser) { described_class.new }
  
  describe '#num' do
    subject { parser.num }
    
    it { should parse('1.23') }
    it { should parse('+1.23') }
    it { should parse('-1.23') }
    it { should parse('.23') }
    it { should parse('+.23') }
    it { should parse('-.23') }
    it { should parse('123') }
    it { should parse('+123') }
    it { should parse('-123') }
    
    it { should_not parse('1a') }
    it { should_not parse('+1a') }
    it { should_not parse('-1a') }
  end
  
  
  describe '#ident' do
    subject { parser.ident }
  
    it { should parse('a') }
    it { should parse('A') }
    it { should parse('aBcD') }
    it { should parse('a1') }
    it { should parse('a1b2c3') }
    
    it { should_not parse('1') }
    it { should_not parse('1a') }
    
    KEYWORDS.each do |k|
      it { should_not parse(k) }
      it { should_not parse("#{k} ") }
      it { should parse("#{k}BLAH") }
      it { should parse("BLAH#{k}") }
    end
  end
  
  
  context '#expr' do
    subject { parser.expr }
    
    it { should parse('1 + b + foo(3) + if 1 then 1 else 0') }
    
    it { should_not parse('x y') }
    it { should_not parse('x + y y + z') }
    
    context 'binary operations' do
      BINARY_OPS.each do |op|
        it { should parse("1#{op}1") }
        
        it { should_not parse("#{op}1") } unless UNARY_OPS.include?(op)
        it { should_not parse("1#{op}") }
        it { should_not parse("1#{op}1#{op}") }
      end
    end
    
    context 'parenthesis' do
      it { should parse('(1+1)') }
      it { should parse('(1+(1+1))') }
      
      it { should_not parse('()') }
      it { should_not parse('(1+())') }
      it { should_not parse('(1+1') }
      it { should_not parse('1+1)') }
      it { should_not parse('(1+1))') }
      it { should_not parse('((1+1') }
    end
  end
  
  
  context '#cond' do
    it { should parse('if 1 then 1 else 0') }
    it { should parse('if 1 > 1 then wtf() else ok()') }
    it { should parse('if a < 0 then a * -1 else a') }
    
    it { should_not parse('if 1 then 1') }
  end
  

  context '#expr_seq' do
    subject { parser.expr_seq }
    
    it { should parse('') }
    it { should parse('1') }
    it { should parse('1,a,3') }
    it { should parse('a , 2 , c') }
    it { should parse('a + 1, 2 + b, c + 3') }
    
    it { should_not parse(',') }
    it { should_not parse(',1') }
    it { should_not parse('1,') }
    it { should_not parse('1 2') }
  end
  
  
  context '#func_call' do
    subject { parser.func_call }
    
    it { should parse('foo()') }
    it { should parse('foo(1)') }
    it { should parse('foo(a, 2)') }
    
    it { should_not parse('foo') }
    it { should_not parse('foo(') }
    it { should_not parse('foo 1') }
  end
  
  
  context '#ident_seq' do
    subject { parser.ident_seq }
    
    it { should parse('') }
    it { should parse('x') }
    it { should parse('x,y,z') }
    it { should parse('x , y , z') }
    
    it { should_not parse(',') }
    it { should_not parse(',x') }
    it { should_not parse('x,') }
    it { should_not parse('x y') }
  end
  

  context '#func_def' do
    subject { parser.func_def }
  
    it { should parse("def foo() 1") }
    it { should parse("def foo(x) x") }
    it { should parse("def foo(x,y,z)x+y+z") }
    it { should parse("def foo(x, y, z) x + y + z") }
    
    it { should_not parse("deffoo() 1") }
  end
  
  
  context '#comment' do
    subject { parser.comment }
    
    it { should parse('#') }
    it { should parse('# THIS IS A COMMENT') }
    
    it { should_not parse("# THIS IS A COMMENT FOLLOWED BY STUFF\n1+1") }
  end
  
  
  it do should parse(
    <<-eos
      def foo(x, y, z) x + y + z
      # some comment  
      1 + foo(2, 3 + 4, 5) + 6
    eos
  ) end
  
  
  context 'whitespace' do
    it { should parse('  1  +  1  ') }
    it { should parse('  (  1  +  1  )  ') }
    it { should parse('  (  1  +  ( 1 +  1 )  )  ') }
  end
end
