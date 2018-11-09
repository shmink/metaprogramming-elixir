defmodule MathTest do
  use Assertion

  test "integers can be added and subtracted" do
    assert 1 + 1 == 2
    assert 2 + 3 == 5
    assert 5 - 5 == 10
  end

  test "ints can be multiplied and divided" do
    assert 5 * 5 == 25
    assert 10 / 2 == 5
    assert 50 / 2 == 40
  end
end
