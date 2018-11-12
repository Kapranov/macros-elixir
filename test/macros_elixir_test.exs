defmodule MacrosElixirTest do
  use ExUnit.Case
  doctest MacrosElixir

  test "greets the world" do
    assert MacrosElixir.hello() == :world
  end
end
