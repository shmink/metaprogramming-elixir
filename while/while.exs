defmodule Loop do
  defmacro while(expression, do: block) do
    quote do
      for _ <- Stream.cycle([:ok]) do
        if unquote(expression) do
          unquote(block)
        else
          # out of loop
        end
      end
    end
  end
end
