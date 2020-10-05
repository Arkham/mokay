defmodule MokayTest do
  use ExUnit.Case
  doctest Mokay

  test "greets the world" do
    assert Mokay.hello() == :world
  end
end
