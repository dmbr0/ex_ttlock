defmodule TTlockClientTest do
  use ExUnit.Case
  doctest TTlockClient

  test "greets the world" do
    assert TTlockClient.hello() == :world
  end
end
