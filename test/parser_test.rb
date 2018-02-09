require "test_helper"
require "parser"

class ParserTest < Minitest::Test

  def self.make_binop(left, op, right)
    [ "#{left[0]}#{op}#{right[0]}",
      Kaleidoscope::OpSequence.new(left[1],
        [Kaleidoscope::OpRight.new(op, right[1])]) ]
  end

  KEYWORDS = %w[def if then else]

  OPERATOR_PRECEDENCE = {
    "*" => 0, "/" => 0,
    "+" => 1, "-" => 1,
    "==" => 2, "!=" => 2, "<" => 2, ">" => 2, "<=" => 2, ">=" => 2,
  }

  BINARY_OPERATORS = OPERATOR_PRECEDENCE.keys

  SOME_LITERALS = [
    *"0".."9",
    *%w[+ - . +. -. 0. +0. -0.].map{|pre| "#{pre}123" },
  ].map{|s| [s, Kaleidoscope::NumLiteral.new(s)] }.to_h

  SOME_IDENTIFIERS = [
    *"a".."z",
    *"A".."Z",
    "Abc", "aBc", "abC",
    *"a0".."a9",
    *"A0".."A9",
    "abc2ABC",
    *KEYWORDS.map{|k| "x#{k}" },
    *KEYWORDS.map{|k| "#{k}x" },
  ].map{|s| [s, Kaleidoscope::Identifier.new(s)] }.to_h

  SOME_EXPRS = [
    SOME_LITERALS.first,
    SOME_IDENTIFIERS.first,
    make_binop(SOME_LITERALS.first, "*", SOME_IDENTIFIERS.first),
    make_binop(SOME_LITERALS.first, "+",
      make_binop(SOME_IDENTIFIERS.first, "*", SOME_IDENTIFIERS.first)),
    make_binop(make_binop(SOME_LITERALS.first, "*", SOME_LITERALS.first),
      "+", SOME_IDENTIFIERS.first),
  ]

  SOME_WHITESPACES = [" ", "  ", " \t\n"]


  def test_numeric_literals
    SOME_LITERALS.each do |input, expected|
      assert_parse expected, input
    end
  end

  def test_identifiers
    SOME_IDENTIFIERS.each do |input, expected|
      assert_parse expected, input
    end
  end

  def test_keywords_are_not_identifiers
    # keywords never occur in isolation, and therefore should fail to
    # parse when by themselves (more specifically, they should not be
    # parsed as identifiers)
    KEYWORDS.each do |s|
      refute_parse(s)
    end
  end

  def test_binary_ops
    operand_pairs = [
      [SOME_LITERALS.first, SOME_IDENTIFIERS.first],
      [SOME_IDENTIFIERS.first, SOME_LITERALS.first],
    ]

    BINARY_OPERATORS.zip(operand_pairs.cycle).each do |op, (left, right)|
      expected = make_binop(left, op, right)[1]
      tokens = [left[0], op, right[0]]
      assert_parse_tokens expected, tokens, contiguous: true
    end
  end

  def test_binary_ops_missing_left_operand
    (BINARY_OPERATORS - %w[+ -]).each do |op|
      refute_parse("#{op}1")
    end
  end

  def test_binary_ops_missing_right_operand
    BINARY_OPERATORS.each do |op|
      refute_parse("1#{op}")
    end
  end

  def test_binary_ops_precedence
    x, y, z = SOME_LITERALS.take(3)

    BINARY_OPERATORS.product(BINARY_OPERATORS).each do |op1, op2|
      input, expected =
        if OPERATOR_PRECEDENCE[op1] < OPERATOR_PRECEDENCE[op2]
          make_binop(make_binop(x, op1, y), op2, z)
        elsif OPERATOR_PRECEDENCE[op1] > OPERATOR_PRECEDENCE[op2]
          make_binop(x, op1, make_binop(y, op2, z))
        else
          make_binop(x, op1, y).tap do |b|
            b[0] << "#{op2}#{z[0]}"
            b[1].rights << Kaleidoscope::OpRight.new(op2, z[1])
          end
        end

      assert_parse expected, input
    end
  end

  def test_parens
    (1..3).each do |n|
      SOME_EXPRS.each do |str, expected|
        tokens = ["("] * n + [str] + [")"] * n
        assert_parse_tokens expected, tokens, contiguous: true
      end
    end
  end

  def test_empty_parens
    (1..3).map{|n| "(" * n + ")" * n }.each do |empty|
      refute_parse(empty)
    end
  end

  def test_imbalanced_parens
    imbalanced = (0..3).map{|n| "(" * n }.product((1..3).map{|n| ")" * n }).
      each{|pair| pair[1] = "" if pair[0].length == pair[1].length }

    imbalanced.each do |lp, rp|
      refute_parse("#{lp}1#{rp}")
    end
  end

  def test_parens_precedence
    x, y, z = SOME_LITERALS.take(3)

    BINARY_OPERATORS.product(BINARY_OPERATORS).each do |op1, op2|
      expected = make_binop(x, op1, make_binop(y, op2, z))[1]
      assert_parse expected, "#{x[0]}#{op1}(#{y[0]}#{op2}#{z[0]})"
    end
  end

  def test_conditional
    SOME_EXPRS.each do |expr|
      expected = Kaleidoscope::Cond.new(expr[1], expr[1], expr[1])
      tokens = ["if", expr[0], "then", expr[0], "else", expr[0]]
      assert_parse_tokens expected, tokens
    end
  end

  def test_function_definition
    (1..4).map{|n| SOME_IDENTIFIERS.take(n) }.zip(SOME_EXPRS.cycle).each do |idents, body|
      func, *params = idents
      expected = Kaleidoscope::FuncDef.new(func[1].name, params.map(&:last).map(&:name), body[1])
      tokens = ["def", func[0], "(", *params.flat_map{|p| [",", p[0]] }.drop(1), ")", body[0]]
      assert_parse_tokens expected, tokens
    end
  end

  def test_function_call
    (0..3).map{|n| SOME_EXPRS.take(n) }.each do |args|
      func = SOME_IDENTIFIERS.first
      expected = Kaleidoscope::FuncCall.new(func[1].name, args.map(&:last))
      tokens = [func[0], "(", *args.flat_map{|a| [",", a[0]] }.drop(1), ")"]
      assert_parse_tokens expected, tokens
    end
  end

  def test_comment
    comments = ["", " ", "\t", "...", [*"a".."z", *"A".."Z", *"0".."9"].join]

    comments.zip(SOME_EXPRS.cycle).each do |comment, expr|
      assert_parse expr[1], "##{comment}\n#{expr[0]}"
    end
  end

  private

  def make_binop(*args)
    self.class.make_binop(*args)
  end

  def assert_parse(expected, input)
    assert_equal expected, Kaleidoscope.parse(input).first
  end

  def assert_parse_tokens(expected, tokens, contiguous: false)
    (SOME_WHITESPACES + (contiguous ? [""] : [])).each do |delim|
      assert_parse expected, tokens.join(delim)
    end
  end

  def refute_parse(input)
    assert_raises(Parslet::ParseFailed) do
      Kaleidoscope.parse(input)
    end
  end

end
