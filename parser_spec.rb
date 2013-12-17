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
  
  
  describe '#expr' do
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
  
  
  describe '#cond' do
    it { should parse('if 1 then 1 else 0') }
    it { should parse('if 1 > 1 then wtf() else ok()') }
    it { should parse('if a < 0 then a * -1 else a') }
    
    it { should_not parse('if 1 then 1') }
  end
  

  describe '#expr_seq' do
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
  
  
  describe '#func_call' do
    subject { parser.func_call }
    
    it { should parse('foo()') }
    it { should parse('foo(1)') }
    it { should parse('foo(a, 2)') }
    
    it { should_not parse('foo') }
    it { should_not parse('foo(') }
    it { should_not parse('foo 1') }
  end
  
  
  describe '#ident_seq' do
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
  

  describe '#func_def' do
    subject { parser.func_def }
  
    it { should parse("def foo() 1") }
    it { should parse("def foo(x) x") }
    it { should parse("def foo(x,y,z)x+y+z") }
    it { should parse("def foo(x, y, z) x + y + z") }
    
    it { should_not parse("deffoo() 1") }
  end
  
  
  describe '#comment' do
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



describe Kaleidoscope::Transform do
  let(:transformer) { described_class.new }
  let(:parser) { Kaleidoscope::Parser.new }
  def transform(src)
    transformer.apply(parser.parse(src)).first
  end
  
  
  context 'transforming' do
    context 'basic expressions' do
      it { transform('x').should be_a(Kaleidoscope::Identifier) }
      it { transform('x+y').should be_a(Kaleidoscope::OpSequence) }
    end
    
    context 'conditionals' do
      subject { transform('if x > y then x - y else y - x') }
      it { should be_a(Kaleidoscope::Cond) }
      its(:test) { should be_a(Kaleidoscope::OpSequence) }
      its(:then_val) { should be_a(Kaleidoscope::OpSequence) }
      its(:else_val) { should be_a(Kaleidoscope::OpSequence) }
    end
    
    context 'function calls' do
      context 'with no args' do
        subject { transform('f()') }
        it { should be_a(Kaleidoscope::FuncCall) }
        its(:args) { should be_a(Array) }
      end
    
      context 'with one arg' do
        subject { transform('f(x + y)') }
        it { should be_a(Kaleidoscope::FuncCall) }
        its(:args) { should be_a(Array) }
        it { subject.args.first.should be_a(Kaleidoscope::OpSequence) }
      end
      
      context 'with multiple args' do
        subject { transform('f(x, y + z)') }
        it { should be_a(Kaleidoscope::FuncCall) }
        its(:args) { should be_a(Array) }
        it { subject.args.first.should be_a(Kaleidoscope::Identifier) }
        it { subject.args.last.should be_a(Kaleidoscope::OpSequence) }
      end
    end
    
    context 'function definitions' do
      context 'with no args' do
        subject { transform('def f() 1') }
        it { should be_a(Kaleidoscope::FuncDef) }
        its(:params) { should be_a(Array) }
        its(:body) { should be_a(Kaleidoscope::NumLiteral) }
      end
    
      context 'with one arg' do
        subject { transform('def f(x) x') }
        it { should be_a(Kaleidoscope::FuncDef) }
        its(:params) { should be_a(Array) }
        its(:body) { should be_a(Kaleidoscope::Identifier) }
      end
      
      context 'with multiple args' do
        subject { transform('def f(x, y) x + y') }
        it { should be_a(Kaleidoscope::FuncDef) }
        its(:params) { should be_a(Array) }
        its(:body) { should be_a(Kaleidoscope::OpSequence) }
      end
    end
  end
  
  
  context 'not leaking Parslet::Slice objects when transforming' do
    context 'variable identifiers' do
      subject { transform('x') }
      its(:name) { should_not be_a(Parslet::Slice) }
      its(:name) { should be_a(String) }
    end
  
    context 'function calls' do
      subject { transform('f(x, y)') }
      its(:name) { should_not be_a(Parslet::Slice) }
      its(:name) { should be_a(String) }
    end
    
    context 'function definitions' do
      subject { transform('def f(x, y) x + y') }
      its(:name) { should_not be_a(Parslet::Slice) }
      its(:name) { should be_a(String) }
      
      # ...would be nice if there was a sweeter way to express these
      it { subject.params.each{|p| p.should_not be_a(Parslet::Slice) } }
      it { subject.params.each{|p| p.should be_a(String) } }
    end
  end
end
