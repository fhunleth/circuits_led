defmodule CircuitsLED.SysClassServer do
  use GenServer

  def start_link(name) do
    GenServer.start(__MODULE__, name, [])
  end

  @doc """
  Turn the specified LED off
  """
  def off(led) do
    GenServer.call(led, :off)
  end

  @doc """
  Turn the specified LED on
  """
  def on(led, color) do
    GenServer.call(led, {:on, color})
  end

  @doc """
  Turn the LED on and off repeatedly

  The LED first turns on for the specified on_time in milliseconds
  and then turns off and then repeats. It repeats `n` times. `n = 0`
  means that it repeats indefinitely.
  """
  def blink(led, on_time, off_time, n) do
    GenServer.call(led, {:blink, on_time, off_time, n})
  end

  @doc """
  Toggle the state of the LED
  """
  def toggle(led) do
    GenServer.call(led, :off)
  end

  @doc """
  Return a list of triggers supported by the LED

  LEDs provided by Linux's `/sys/class` interface can be triggered
  by system events to show off things like CPU, disk and network
  usage. This function returns supported triggers.
  """
  def get_triggers(led) do
    GenServer.call(led, :get_triggers)
  end

  @doc """
  Support setting triggers on LEDs

  Call `triggers/1` to get a list of what triggers are available for the
  LED.

  Put the LED into heartbeat mode:

      iex> CircuitsLED.set_trigger(led, "heartbeat")
      :ok
  """
  def set_trigger(led, trigger, options \\ []) do
    GenServer.call(led, {:set_trigger, trigger, options})
  end

  @impl true
  def init(name) do
    {:ok, max_brightness} = read(name, "max_brightness")
    {:ok, brightness} = read(name, "max_brightness")
    {:ok, %{name: name, brightness: brightness, max_brightness: max_brightness}}
  end

  @impl true
  def handle_call(:off, _from, %{name: name} = state) do
    case write(name, "brightness", 0) do
      :ok ->
        {:reply, :ok, %{state | brightness: 0}}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:on, _from, %{name: name, max_brightness: max_brightness} = state) do
    case write(name, "brightness", max_brightness) do
      :ok ->
        {:reply, :ok, %{state | brightness: max_brightness}}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:toggle, _from, %{name: name} = state) do
    new_brightness = toggle_brightness(state.brightness, state.max_brightness)

    case write(name, "brightness", new_brightness) do
      :ok ->
        {:reply, :ok, %{state | brightness: new_brightness}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:)
  defp toggle_brightness(brightness, max_brightness) when brightness == max_brightness do
    0
  end

  defp toggle_brightness(_brightness, max_brightness) do
    max_brightness
  end

  defp write(name, attribute, value) do
    File.write(path(name, attribute), to_string(value))
  end

  defp read(name, attribute) do
    File.read(path(name, attribute))
  end

  defp path(name, attribute) do
    Path.join(["/sys/class/leds", name, attribute])
  end
end
