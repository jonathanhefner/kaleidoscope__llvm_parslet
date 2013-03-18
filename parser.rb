require 'parslet'


module Kaleidoscope
  class Parser < Parslet::Parser
    rule(:sp) { match('\s').repeat(1) }
    rule(:sp?) { sp.maybe }
    rule(:sign) { match('[+-]') }
    rule(:sign?) { sign.maybe }
    rule(:alpha) { match('[a-zA-Z]') }
    rule(:alphanum) { match('[a-zA-Z0-9]') }
    rule(:digit) { match('[0-9]') }
    rule(:digits) { digit.repeat(1) }
    
    rule(:delim) { str(',') >> sp? }
    rule(:lparen) { str('(') >> sp? }
    rule(:rparen) { str(')') >> sp? }
    rule(:eol) { str("\n") >> str("\r").maybe }
    rule(:eow) { sp | any.absent? }
    
    rule(:mult_op) { match('[*/]').as(:op) >> sp? }
    rule(:add_op) { match('[+-]').as(:op) >> sp? }
    rule(:comp_op) { match('[<>]').as(:op) >> sp? }
    
    rule(:func_start) { str('def') >> eow }
    rule(:keyword) { func_start }
    
    rule(:frac) { str('.') >> digits }
    rule(:num) { (sign? >> ((digits >> frac.maybe) | frac)).as(:num) >> sp? }
    
    rule(:ident) { keyword.absent? >> (alpha >> alphanum.repeat).as(:ident) >> sp? }
    
    # parslet implements PEG, therefore no left-recursion
    rule(:e3) { (lparen >> expr >> rparen) | num | ident }
    rule(:e2) { (e3.as(:left) >> (mult_op >> e3.as(:right)).repeat(1).as(:rights)) | e3 }
    rule(:e1) { (e2.as(:left) >> (add_op >> e2.as(:right)).repeat(1).as(:rights)) | e2 }
    rule(:e0) { (e1.as(:left) >> (comp_op >> e1.as(:right)).repeat(1).as(:rights)) | e1 }
    rule(:expr) { e0 }

    rule(:ident_seq) { delim.absent? >> ident.maybe >> (delim >> ident).repeat }
    rule(:func_def) { func_start >> ident >> lparen >> ident_seq.as(:params) >> rparen >> expr.as(:body) }
    
    rule(:comment) { str('#') >> (eol.absent? >> any).repeat }
    
    rule(:top) { (sp? >> (comment | func_def | expr) >> sp?).repeat(1) }
    root(:top)
  end


  class NumLiteral < Struct.new(:val)
  end
  
  
  class Identifier < Struct.new(:name)
  end


  class OpRight < Struct.new(:op, :right)
  end


  class OpSequence < Struct.new(:left, :rights)
  end
  
  
  class FuncDef < Struct.new(:name, :params, :body)
  end


  class Transform < Parslet::Transform
    rule(num: simple(:val)) {
      NumLiteral.new(val)
    }
    
    rule(ident: simple(:name)) {
      Identifier.new(name)
    }
    
    rule(op: simple(:op), right: subtree(:right)) {
      OpRight.new(op, right)
    }
    
    rule(left: subtree(:left), rights: sequence(:rights)) {
      OpSequence.new(left, rights)
    }
    
    rule(ident: simple(:name), params: sequence(:params), body: subtree(:body)) {
      FuncDef.new(name, params, body)
    }
  end


  def self.parse(src)
    Transform.new.apply(Parser.new.parse(src))
  end
  
end