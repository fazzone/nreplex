defmodule NreplTest do
  use ExUnit.Case
  doctest Nrepl

  test "greets the world" do
    assert Nrepl.hello() == :world
  end
end
