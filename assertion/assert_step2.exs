defmodule Assertion do
  defmacro assert({operator, _, [lhs, rhs]}) do
    quote bind_quoted: [operator: operator, lhs: lhs, rhs: rhs] do
      Assertion.Test.assert(operator, lhs, rhs)
    end
  end
end

defmodule Assertion.Test do
  def pass do
    [:green, :bright, "PASSED!"]
    |> IO.ANSI.format()
    |> IO.puts()
  end

  def fail(lhs, rhs) do
    fail =
      [:red, :bright, "FAILED:"]
      |> IO.ANSI.format()

    IO.puts("""
    #{fail}
    Expected:     #{lhs}
    but received: #{rhs}
    """)
  end

  def assert(operator, lhs, rhs) do
    case operator do
      :== -> if lhs == rhs, do: pass(), else: fail(lhs, rhs)
      :> -> if lhs > rhs, do: pass(), else: fail(lhs, rhs)
      :< -> if lhs < rhs, do: pass(), else: fail(lhs, rhs)
    end
  end
end
