## Chapter 2 - Extending Elixir with Metaprogramming

#### Re-Creating the if Macro

-   Let's re-create the `if` macro.

[if.exs](../if/if.exs)

<details>
<summary>if.exs</summary>

```elixir
defmodule ControlFlow do
  defmacro my_if(expr, do: if_block), do: if(expr, do: if_block, else: nil)

  defmacro my_if(expr, do: if_block, else: else_block) do
    quote do
      case unquote(expr) do
        result when result in [false, nil] -> unquote(else_block)
        _ -> unquote(if_block)
      end
    end
  end
end
```

Output:

```elixir
iex(1)> ControlFlow.my_if 1 == 1 do
...(1)> "correct"
...(1)> else
...(1)> "incorrect"
...(1)> end
"correct"
```

</details>

#### Adding a while Loop to Elixir

-   There is, obviously no `while` loop in the language.
-   If you find yourself needing a feature that elixir doesn#t natively support you can add it through macros.
-   There is no built-in way in elixir to loop indefinatley so we need to _cheat_ to create our `while` loop.

[while.exs](../while/while.exs)

<details>
<summary>while.exs</summary>

```elixir
defmodule Loop do
  defmacro while(expression, do: block) do
    quote do
      for _ <- Stream.cycle([:ok]) do
        if unquote(expression) do
          unquote(block)
        else
          IO.puts("out of loop")
        end
      end
    end
  end
end
```

Output:

```elixir
iex> while true do
...>    IO.puts "looping!"
...> end
looping!
looping!
looping!
looping!
looping!
looping!
looping!
...
^C^C
```

</details>

In `while.exs` we were able to repeatedly execute a block of code given an expression. Next, a way to break out of execution once the expression is no longer true. Elixirs `for` loop has no built-in way to terminate early.

[while_step2.exs](../while/while_step2.exs)

<details>
<summary>while_step2.exs</summary>

```elixir
defmodule Loop do
  defmacro while(expression, do: block) do
    quote do
      try do
        for _ <- Stream.cycle([:ok]) do
          if unquote(expression) do
            unquote(block)
          else
            throw(:break)
          end
        end
      catch
        :break -> :ok
      end
    end
  end
end
```

Output:

```elixir
iex(1)> c "while_step2.exs"
[Loop]

iex(2)> import Loop
Loop

iex(3)> run_loop = fn ->
...(3)>   pid = spawn(fn -> :timer.sleep(4000) end)
...(3)>   while Process.alive?(pid) do
...(3)>     IO.puts "#{inspect :erlang.time} Stayin' alive!"
...(3)>     :timer.sleep 1000
...(3)>   end
...(3)> end
#Function<20.128620087/0 in :erl_eval.expr/5>

iex(4)> run_loop.()
{10, 40, 45} Stayin' alive!
{10, 40, 46} Stayin' alive!
{10, 40, 47} Stayin' alive!
{10, 40, 48} Stayin' alive!
:ok
```

</details>

Careful use of `throw` allows us to break out of execution whenever the `while` expression is no longer true.

#### Smarter Testing with Macros

-   By providing unique functions per assertion, the correct failure messages can be generated, but it comes at a cost of larger testing API.
-   Macros power elixirs `ExUnit` test fromwork. 

##### Supercharged Assertions

-   The goal for our `assert` macro is to accept a left-hand side and right-hand side expression, separated by an elixir operator, such as `assert 1 > 0`.
-   If an assertion fails, we'll print a helpful failure message based on the expression being tested.
-   Our macro will peek inside the representation of the assertions in order to print the correct test output.

Here is waht we want to accomplish:

```elixir
defmodule Test do
  import Assertion
  def run
    assert 5 == 5
    assert 2 > 0
    assert 10 < 1
  end
end


iex> Test.run
FAILURE:
  Expected: 10
  to be less than: 1
```

-   Going back to what these ASTs look like in preperation for the testing framework macros.

```elixir
iex(5)> quote do: 5 + 5
{:+, [context: Elixir, import: Kernel], [5, 5]}

iex(6)> quote do: 5 ==  5
{:==, [context: Elixir, import: Kernel], [5, 5]}

iex(10)> example
5

iex(11)> quote do: example + 5
{:+, [context: Elixir, import: Kernel], [{:example, [], Elixir}, 5]}

iex(12)> quote do: unquote(example) + 5
{:+, [context: Elixir, import: Kernel], [5, 5]}
```

[assert_step1.exs](../assertion/assert_step1.exs)

<details>
<summary>assert_step1.exs</summary>

```elixir
defmodule Assertion do
  # {:==, [context: Elixir, import: Kernel], [5, 5]}
  defmacro assert({operator, _, [lhs, rhs]}) do
    quote bind_quoted: [operator: operator, lhs: lhs, rhs: rhs] do
      Assertion.Test.assert(operator, lhs, rhs)
    end
  end
end
```

</details>

In `assert_step1.exs` we did some pattern matching directly on the provided AST expression, using out `iex` examples to match our argument.
`bind_quoted` was also used for the first time. 

##### bind_quoted

`bind_quoted` option passes a binding to the block, ensuring that the outside bound variables are unquoted only a single time. This macro could have been written without `bind_quoted`, but it's good practice to use it whenever possible to prevent accidental re-evaluation of bindings. The following blocks are equivalent:

```elixir
quote bind_quoted: [operator: operator, lhs: lhs, rhs: rhs] do
    Assertion.Test.assert(operator, lhs, rhs)
end

quote do
    Assertion.Test.assert(unquote(operator), unquote(lhs), unquote)rhs))
end
```

-   You can use bind_quoted to clear up your code and remove all the extra and now uneeded `unquote`s.
-   Using `bind_quoted` also will help keep safe from re-evaluations which is where you unquote more than once.

##### Leveraging the VM's Pattern Matching Engine

-   Now we can implement the proxy `assert` functions in a new `Assertion.Test` module. The module will carry out the work of performing the assertions and running our tests.

[assert_step2.exs](../assertion/assert_step2.exs)

<details>
<summary>assert_step2.exs</summary>

```elixir
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
```

Output:

```elixir
iex(1)> c "assert_step2.exs"
[Assertion.Test, Assertion]

iex(2)> import Assertion
Assertion

iex(3)> assert 1 > 2
FAILURE:
  Expected:           1
  to be greater than: 2

iex(4)> assert 5 == 5
:ok

iex(5)> assert 10 * 10 == 100
:ok

iex(6)> assert 10 * 10 == 101
FAILURE:
Expected:       100
to be equal to: 101
```

</details>

-   This is a start of a test framework. Moving onto being able to group tests by name or description.

#### Extending Modules

-   Core purpose of macros is to inject code into modules to extend their behaviour, define functions, and perform any other code generation that's required.
-   Lets extend other modules with a `test` macro where it will accept a test-case description as a string and then followed by a block of code where assertions can be made.
-   We'll also define the `run/0` function automatically for the caller so that all test cases can be executed by a single function call.

##### Module Extension Is Simply Code Injection

-   Most metaprogramming in Elixir is done within module definitions to extend other modules with extra functionality.

[module_extension.exs](../module-extension/module_extension.exs)

<details>
<summary>module_extension.exs</summary>

```elixir
defmodule Assertion do
  # ...
  defmacro __using__(options \\ []) do
    quote do
      import unquote(__MODULE__)

      def run do
        IO.puts("Running the tests...")
      end
    end
  end

  # ...
end

defmodule MathTest do
  use Assertion
end
```

Output:

```elixir
iex> MathTest.run
Running the tests...
:ok
```

</details>

-   `Assertion.extend` is just a regular macro that returned an AST containing the `run/0` definition. This example however underlines the building-block nature of elixirs code constructions. With no other mechanism tan `defmacro` and `quote`, we defined a function within another module!

##### use: A common API for Module Extension

-   A recurring theme in elixir libraries is the commonaility of `use SomeModule` syntax.
-   The `use` macro serves the simple but powerful purpose of providing a common API for module extension. `use SomeModule` simply invokes the `SomeModule.__using__/1` macro.
-   By providing a common API for extension, this little macro will be the center of the metaprogramming.
-   On lines 3 and 16 from `module_extension.exs` we _use_ `use` and `__using__`.
-   `use` seems like an untouchable keyword, but in reality it's just a macro that does a bit of code injection like our own `extend` definition. 

##### Using Module Attributes for Code Generation

-   We need to be able to define multiple test cases as well as a way to track each case-definition for inclusion within `MathTest.run/0`. We can solve this however with "module attributes".
-   Module attributes allow data to be stored in the module at compile time.
-   These are often used in places where constants would be applied in other languages, but elixir provides other tricksfor us to exploit furing compilation.
-   Taking advantage of the `accumulate: true` option when regestering an attribute, we can keep an appened list of registrations during the compile phase.
-   After the module is compiled, the attribute contains a list of all registrations that occurred during compilation. Let's see how this can be used for our `test` macro.

[accumulated_module_attributes.exs](../module-extension/accumulated_module_extension.exs)

<details>
<summary>accumulated_module_extension.exs</summary>

```elixir
defmodule Assertion do
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute(__MODULE__, :tests, accumulate: true)

      def run do
        IO.puts("Running the tests (#{inspect(@tests)}")
      end
    end
  end

  defmacro test(description, do: test_block) do
    test_func = String.to_atom(descriptions)

    quote do
      @tests {unquote(test_func), unquote(description)}
      def unquote(test_func)(), do: unquote(test_block)
    end
  end
end
```

</details>
