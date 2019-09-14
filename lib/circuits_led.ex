defmodule CircuitsLED do
  @moduledoc """
  Control LEDs

  This module provides a consistent way of controlling LEDs on devices
  running Nerves or Linux.

  Use cases I'm thinking about:

  1. Control `/sys/class` LEDs and GPIO LEDs using functions to make
     things easier on users who don't know about Linux's LED subsystem.
     Also, since it's really hard for most Nerves users (and me too) to
     add an LED to Linux's LED subsystem, I like the idea of controlling
     LEDs via GPIOs without going straight to `circuits_gpio`.
  2. Blink LEDs
  3. Combine one or more LEDs and be able to set them with a color. For
     example, it's common to have a red, green, and blue LED in one device.
     It would be nice to set them with one API call rather than make
     a three separate calls
  4. Support Linux's LED subsystems triggers so that LEDs can be
     used for CPU, disk, and network activity.

  Questions?

  1. Expose a GenServer or not? Decided yes.
  2. Require users to "open" LEDs before use? I.e., is the user responsible for
     resource management? Decided yes, but since GenServer, they'll be
     start_linking.
  """

  @typedoc """
  Named LEDs are LEDs that have been given names in Linux

  For example, the Beaglebone Black boards have the following named LEDs:

  * "beaglebone:green:usr0"
  * "beaglebone:green:usr1"
  * "beaglebone:green:usr2"
  * "beaglebone:green:usr3"
  """
  @type named_led :: String.t()

  @typedoc """
  A GPIO LED is an LED that's connected via a GPIO pin
  """
  @type gpio_led :: {:gpio, non_neg_integer()}

  @typedoc """
  A LED
  """
  @type led_spec :: named_led() | gpio_led()

  @typedoc """
  Maybe a reference to the LED from when it has been opened or
  maybe the led_spec()?
  """
  @type led_ref :: term()

  @typedoc """
  TBD LED color

  Nearly all LEDs controlled by this API can only be turned on and off.
  Sometimes there are bicolor and RGB LEDs and sometimes it's possible
  to set the LED brightness.
  """
  @type color :: term()

  @doc """
  Return a list of LEDs that have names
  """
  @spec named_leds() :: [named_led()]
  def named_leds() do
    case File.ls("/sys/class/leds") do
      {:ok, leds} -> leds
      _ -> []
    end
  end

  @doc """
  TODO: Refactor this to make each LED be a proper GenServer so that it can be supervised,
  serialize multi-operation requests to Linux, and do things like blink.
  """
  @spec start_link(led_spec(), keyword()) :: GenServer.on_start()
  def start_link(led, opts \\ []) do
    GenServer.start_link(__MODULE__, led, opts)
  end

  @doc """
  Turn the specified LED off
  """
  @spec off(led_ref()) :: :ok
  def off(_led) do
    :ok
  end

  @doc """
  Turn the specified LED on
  """
  @spec on(led_ref(), color()) :: :ok
  def on(_led, _color) do
    :ok
  end

  @doc """
  Turn the LED on and off repeatedly

  The LED first turns on for the specified on_time in milliseconds
  and then turns off and then repeats. It repeats `n` times. `n = 0`
  means that it repeats indefinitely.
  """
  @spec blink(led_ref(), non_neg_integer(), non_neg_integer(), non_neg_integer()) :: :ok
  def blink(_led, _on_time, _off_time, _n \\ 0) do
    :ok
  end

  @doc """
  Toggle the state of the LED
  """
  @spec toggle(led_ref()) :: :ok
  def toggle(_led) do
    :ok
  end

  @doc """
  Return true if the LED is on
  """
  @spec is_lit(led_ref()) :: false
  def is_lit(_led) do
    false
  end

  @doc """
  Return a list of triggers supported by the LED

  LEDs provided by Linux's `/sys/class` interface can be triggered
  by system events to show off things like CPU, disk and network
  usage. This function returns supported triggers.
  """
  def triggers(_led) do
    []
  end

  @doc """
  Support setting triggers on LEDs

  Call `triggers/1` to get a list of what triggers are available for the
  LED.

  Put the LED into heartbeat mode:

      iex> CircuitsLED.set_trigger(led, "heartbeat")
      :ok
  """
  def set_trigger(_led, _trigger, _options \\ []) do
    :ok
  end
end
