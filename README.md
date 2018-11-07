# Metaprogamming Elixir

## by Chris McCord (author of the Phoenix framework)

_Write less code, get more done (and have fun!)_ :purple_heart:

### Abstract

Reading this book to learn about how macros work and following some of the relevant
examples. This README will serve as my notes, therefore you shouldn't take them at face
value as the notes will make sense for me as I cherry pick a sentence or an analogy.
Moreover, don't expect direct quotes, changing the sentences vocbulary helps me personally.

<details>
<summary>
    ### Chapter 1 - The language of macros 
</summary>

-   Macros are code that write code.
-   Elixir itself is made with macros, as a result you can extend the language itself
    to include things you think you might need.
-   Metaprogramming in elixir serves the purpose of extensibility by design.
-   With this power one can even define languages within elixir. The following is a valid Elixir program.

```elixir
div do
    h1 class: "title" do
        text "Hello"
    end
    p do
        text "Metaprogramming Elixir"
    end
end
"<div><h1 class=\"title\">Hello</h1><p>Metaprogramming Elixir</p></div>"
```

#### The Abstract Syntax Tree

-   Most languages use AST but you never need to know about them. They are used typically during compilation
    or interpretation to transform source code into a tree structure before being turned into bytecode
    or machine code..
-   José Valim, the creator of Elixir, chose to expose this AST and the syntax to interact with it.
-   We can now operate at the same level as the compiler.
-   Metaprogramming in Elixir revolves around manipulating and accessing ASTs.
-   To access the AST representation we use the `quote` macro.

```elixir
iex> quote do: 1 + 2
{:+, [context: Elixir, import: Kernel], [1, 2]}
```

```elixir
iex> quote do: div(10, 2)
{:div, [context: Elixir, import: Kernel], [10, 2]}
```

-   This is the internals of the Elixir language itself.
-   This gives you easy options for infering meaning and optimising performance all while being within Elixirs high level syntax.
-   The purpose of macros is to interact with this AST with the syntax of Elixir.
-   Macros turn you from language consumer to language creator. You have the same level of power as José when he wrote the standard library.

#### Trying It All Together

"Let's write a macro that can print the spoken form of an Elixir mathematical expression, such as 5 + 2, when calculating a result.
In most languages, we would have to parse a string expression into something digestible by our program. With Elixir, we can access
the representation of expressions directly with macros."

[First macro - `math.exs`](math.exs)

<!-- <details>
    <summary> [First macro - `math.exs`](math.exs) </summary>
    ```elixir
        defmodule Math do
        @moduledoc false

        defmacro say({:+, _, [lhs, rhs]}) do
            quote do
            lhs = unquote(lhs)
            rhs = unquote(rhs)
            result = lhs + rhs
            IO.puts("#{lhs} plus #{rhs} is #{result}")
            result
            end
        end

        defmacro say({:*, _, [lhs, rhs]}) do
            quote do
            lhs = unquote(lhs)
            rhs = unquote(rhs)
            result = lhs * rhs
            IO.puts("#{lhs} times #{rhs} is #{result}")
            result
            end
        end
        end
    ``` 
</details> -->

Note when you use this in iex you need to first `c "math.exs"` then `require Math` but i've included it in [.iex.exs](.iex.exs) to save time.
Automagically adding these when you open iex with `iex math.exs`.

In this example. We take what we know from the AST representations so far from the `quote` we used. We then create `defmacro`-s. We can still
have many function clauses with macros. With that, we create two macros called `say` and we pattern match on the AST with the defining feature
being the operator at the start of the AST, `{:+, ...}`, and use a new keyword called `unquote`. From the docs:

```elixir
iex(1)> h unquote

                             defmacro unquote(expr)

Unquotes the given expression from inside a macro.

## Examples

Imagine the situation you have a variable value and you want to inject it
inside some quote. The first attempt would be:

    value = 13
    quote do
      sum(1, value, 3)
    end

Which would then return:

    {:sum, [], [1, {:value, [], quoted}, 3]}

Which is not the expected result. For this, we use unquote:

    iex> value = 13
    iex> quote do
    ...>   sum(1, unquote(value), 3)
    ...> end
    {:sum, [], [1, 13, 3]}
```

I assume from this then when you pass variables to a macro they need to be `unqoute`-d, incontrast to passing a value directly.
Which I'm not following as Elixir is pass-by-value so wouldn't the value just be known?

Yes that's correct because we are dealing with ASTs not the data it represents; therefore the pass-by-value argument doesn't hold.
Much like interpolation from Ecto and the difference between `"Hello world"` and `"Hello #{world}`.

Back to the `math.exs`example. 

</details>
