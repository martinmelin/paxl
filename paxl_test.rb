require 'test/unit'
require 'paxl'

class TestPaxl < Test::Unit::TestCase
  
  # all tests run using the same global scope
  def initialize(arg)
    super(arg)
    @paxl = Paxl::Parser.new
    @paxl_scope = Paxl::Scope.new(nil)
  end
  
  def assert_returns(value, code)
    assert_equal(value, @paxl.parse(code).eval(@paxl_scope))
  end
  
  def test_y_combinator
    assert_returns 120, "
    y = { |g| 
      f = { |x| 
        { |arg| 
          gx = g(x(x));
          gx(arg)
        }
      };
      f(g)
    };
    fg = { |cb|
      { |arg|
        if (arg == 0) { 1 }
        else { arg * (cb(arg - 1)) }
      }
    };
    factorial = y(fg);
    factorial(5)"
  end
  
  def test_this_keyword
    assert_returns 120, "
      factorial = { |x|
        if (x == 0) { 1 }
        else { x * (this(x - 1)) }
      };
      factorial(5)"
  end
  
  def test_for_loops
    assert_returns 45, "a = 0; for (i = 0; i < 10; i = i + 1) { a = a + i }; a"
  end
  
  def test_if_statements
    assert_returns 10, "a = 5; if (a < 10) { 10 } else { a }"
    assert_returns 15, "a = 15; if (a < 10) { 10 } else { a }"
    assert_returns 10, "a = 10; if (a == 10) { 10 }"
  end
  
  def test_blocks
    assert_returns 200, "a = { |b, c| b * c }; a(10; 20)"
    assert_returns 250, "n = 50; a = { |b, c| b * c + n }; a(10; 20)"
    assert_returns 10, "a = { 10 }; a();"
    assert_returns 10, "a = { |x, y, z| (x * y) - z }; a(5; 4; 10)"
  end
  
  def test_variable_assignment
    assert_returns 10, "a = 10"
    assert_returns 10, "a = 10"
    assert_returns 5, "b = 5"
    assert_returns 10, "a"
    assert_returns 5, "b"
    assert_returns 50, "a * b"
  end
  
  def test_basic_math
    assert_returns 10, "5 + 5"
    assert_returns 10, "15 - 5"
    assert_returns 10, "100 / 10"
    assert_returns 10, "5 * 2"
  end
  
  def test_logical_expressions
    assert_returns true, "true"
    assert_returns false, "false"
    assert_returns true, "true and true"
    assert_returns false, "true and false"
    assert_returns true, "false or true"
    assert_returns true, "not false"
  end
  
  def test_comparisons
    assert_returns true, "10 == 10"
    assert_returns false, "1 == 2"
    assert_returns true, "1 != 2"
    assert_returns true, "1 < 2"
    assert_returns true, "1 <= 2"
    assert_returns false, "1 >= 2"
    assert_returns false, "1 > 2"
  end
  
  def test_nested_expressions
    assert_returns true, "(true or false) and (true and true)"
    assert_returns true, "(10 < 20) and (20 >= 10)"
    assert_returns true, "a = ( (true or false) and (true and true) )"
  end
  
end