# MacrosElixir

Elixir is modern, dynamic and functional language that embrace
concurrency and immutability and provide rich metaprogramming
capabilities through macros. To understand macros let us look at how
typically code execution works in any language —

```bash
Code → Lexical Analysis & Parsing → AST → Execution
```
When we write normal functions, we usually do not care about how they
are evaluated / executed internally. However, with macros we can work
with the **AST (Abstract Syntax Tree)** level directly and manipulate
the code there which provides  us with unprecedented  flexibility  to
create new language constructs and DSLs.

![ast](/ast_transform.png "ast tree")

We will take a simple example Elixir macros. We will write a macro that
takes a piece of code and reports the time of execution around it.

To see measurable results we will take an algorithm that is time
consuming, nothing better than calculating Collatz sequences.
The problem statement -

The following iterative sequence is defined for the set of positive
integers:

`n → n/2 (n is even)`
`n → 3n + 1 (n is odd)`

Using the rule above and starting with `13`, we generate the following
sequence: ` 13 → 40 → 20 → 10 → 5 → 16 → 8 → 4 → 2 → 1`.

It can be seen that this sequence (starting at 13 and finishing at 1)
contains 10 terms. Although it has not been proved yet (Collatz
Problem), it is thought that all starting numbers finish at 1. Which
starting number, under one million, produces the longest chain?

The code is simple enough -

```elixir
defmodule Euler do
  @moduledoc false

  require Timer

  @doc false
  def collatz do
    1..1_000_000
      |> Enum.chunk_every(100)
      |> Enum.map(fn(arr) -> pmap(arr) end)
      |> List.flatten
      |> Enum.with_index(1)
      |> Enum.max_by(fn(t) -> elem(t, 0) end)
      |> IO.inspect
  end

  @doc false
  def macro_collatz do
    Timer.time_it "collatz" do
      1..1_000_000
        |> Enum.chunk_every(100)
        |> Enum.map(fn(arr) -> pmap(arr) end)
        |> List.flatten
        |> Enum.with_index(1)
        |> Enum.max_by(fn(t) -> elem(t, 0) end)
        |> IO.inspect
    end
  end

  @doc false
  defp pmap(collection) do
    collection
      |> Enum.map(&(Task.async(fn -> calc(&1, [&1]) end)))
      |> Enum.map(&Task.await/1)
  end

  @doc false
  defp calc(num, acc) do
    num = trunc(num)
    dec = num / 2
    inc = (num * 3) + 1
    r = rem(num, 2)

    case {num, r} do
      {1, _} -> length(acc)
      {_, 0} -> calc(dec, [dec | acc])
      {_, 1} -> calc(inc, [inc | acc])
    end
  end
end
```

Now lets build the timing macro in Elixir -

```elixir
defmodule Timer do
  @moduledoc false

  defmacro time_it(name, do: block) do
    quote do
      start_time = Time.utc_now
      result = unquote(block)
      IO.puts "Elapsed time for #{unquote(name)}: #{Time.diff(Time.utc_now, start_time, :milliseconds)} milliseconds"
      result
    end
  end
end
```

As mentioned earlier, macros work at the AST level, so a macro gets the
AST version of the code and then needs to return the manipulated AST
version of the code. In Elixir we can produce the AST easily by quote,
in example above we inject the code which we need to execute / time and
merge it in our custom quoted AST using unquote. So to time our collatz
function we can write it as (among other ways) - `macro_collatz`, or
from the REPL - `iex> Timer.time_it "collatz", do: Euler.macro_collatz`

which gives us -

```bash
Elapsed time for collatz: 10184 milliseconds
{525, 837799}
```
or into in our the project:

```bash
bash> make all
iex> c "lib/macros_elixir.ex""
iex> MacrosElixir.collatz       #=> {525, 837799}
iex> MacrosElixir.macro_collatz #=> Elapsed time for collatz: 16775 milliseconds
                                #=> {525, 837799}
```

That's it. We looked at macros and built a simple in Elixir. As usual,
with great power comes great responsibility, macros are powerful but
should only be used when a normal function cannot do the job.

### 12 November 2018 by Oleg G.Kapranov
