defmodule MqttNetatmoGwTest do
  use ExUnit.Case
  doctest MqttNetatmoGw

  test "greets the world" do
    assert MqttNetatmoGw.hello() == :world
  end
end
