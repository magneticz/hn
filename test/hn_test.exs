defmodule HNTest do
  use ExUnit.Case
  doctest HN

  test "greets the world" do
    assert HN.hello() == :world
  end
end
