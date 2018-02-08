require "test_helper"
require "compiler"

class CompilerTest < Minitest::Test

  DIGITS = ("0".."9").zip((0..9).map(&:to_f))

  def test_literals
    DIGITS.each do |str, val|
      assert_float(val, str)
      assert_float(-val, "-#{str}")
      assert_float(val + 0.5, "#{str}.5")
    end
  end

  def test_addition
    DIGITS.each do |str, val|
      assert_float(val + (val / 10.0), "#{str} + .#{str}")
    end
  end

  def test_subtraction
    DIGITS.each do |str, val|
      assert_float(val - (val / 10.0), "#{str} - .#{str}")
    end
  end

  def test_multiplication
    DIGITS.each do |str, val|
      assert_float(val * (val / 10.0), "#{str} * .#{str}")
    end
  end

  def test_division
    DIGITS.each do |str, val|
      if val == 0
        assert_float(Float::NAN, "#{str} / .#{str}")
      else
        assert_float(val / (val / 10.0), "#{str} / .#{str}")
      end
    end
  end

  def test_less_than
    mid = DIGITS[5]

    DIGITS.each do |str, val|
      assert_bool(val < mid[1], "#{str} < #{mid[0]}")
      assert_bool(mid[1] < val, "#{mid[0]} < #{str}")
    end
  end

  def test_greater_than
    mid = DIGITS[5]

    DIGITS.each do |str, val|
      assert_bool(val > mid[1], "#{str} > #{mid[0]}")
      assert_bool(mid[1] > val, "#{mid[0]} > #{str}")
    end
  end

  # NOTE The tests for individual operator precedence are in
  # parser_test.rb.  This test checks whether an AST that reflects
  # correct precedence is properly compiled.
  def test_precedence
    DIGITS.drop(1).each do |str, val|
      assert_float(1.0, "1 + #{str} * #{str} / #{str} / #{str} - 1")
    end
  end

  def test_conditional
    DIGITS.take(3).each do |str, val|
      expected = val + (val.zero? ? 0.3 : 0.7)

      assert_float(expected, "if #{str} then #{str}.7 else #{str}.3")
    end
  end

  def test_function
    operands = %w[1 x y z]

    (0..3).each do |cardinality|
      params = operands.drop(1).take(cardinality).join(",")
      body = operands.take(cardinality + 1).join("+")
      arg_digits = DIGITS.last(cardinality)
      args = arg_digits.map(&:first).join(",")
      expected = arg_digits.map(&:last).reduce(&:+).to_f + 1.0

      assert_float(expected, "def f(#{params}) #{body}   f(#{args})")
    end
  end

  def test_recursion
    DIGITS.each do |str, val|
      expected = (1.0..val).step(1.0).reduce(&:*) || 1.0
      assert_float(expected, "def fac(n) if n > 1 then n * fac(n - 1) else 1   fac(#{str})")
    end
  end

  def test_undefined_function
    refute_result "f()"
  end

  def test_undefined_parameter
    refute_result "def f() x"
  end

  def test_redefined_function
    refute_result "def f() 1   def f() 2"
  end

  def test_too_many_args
    refute_result "def f() 1   f(1)"
  end

  def test_too_few_args
    refute_result "def f(x) x   f()"
  end

  private

  def assert_float(expected, input)
    actual = Kaleidoscope.compile_run(input)
    if expected.nan?
      assert_predicate actual, :nan?
    else
      assert_in_delta expected, actual, 0.001
    end
  end

  def assert_bool(expected, input)
    assert_float(expected ? 1.0 : 0.0, input)
  end

  def refute_result(input)
    assert_raises do
      Kaleidoscope.compile_run(input)
    end
  end

end
