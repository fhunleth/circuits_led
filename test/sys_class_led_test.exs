defmodule SysClassLedTest do
  use ExUnit.Case

  alias CircuitsLED.SysClass

  test "parses triggers" do
    assert {:ok, [:none, :mmc0, :timer, :oneshot, :heartbeat, :gpio, :default_on, :transient]} ==
             SysClass.parse_triggers(
               "[none] mmc0 timer oneshot heartbeat gpio default-on transient"
             )
  end
end
