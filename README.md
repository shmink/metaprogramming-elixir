# Metaprogamming Elixir by Chris McCord

_Write less code, get more done (and have fun!)_ :purple_heart:

## Abstract

Reading this book to learn about how macros work and following some of the relevant
examples. This README will serve as my notes, therefore you shouldn't take them at face
value as the notes will make sense for me as I cherry pick a sentence or an analogy.
Moreover, don't expect direct quotes, changing the sentences vocbulary helps me personally.

## Chapter 1 - The language of macros

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
In most languages, we would have to parse a string expression into something digestible by our program. With Elixr, we can access
the representation of expressions directly with macros."

[First macro](math.exs)
