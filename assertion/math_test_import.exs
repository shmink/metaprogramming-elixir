defmodule MathTest do
  import Assertion

  def run do
    assert 5 == 5
    assert 10 > 0
    assert 1 > 2
    assert 10 * 10 == 100
    assert 10 * 10 == 101
  end
end
