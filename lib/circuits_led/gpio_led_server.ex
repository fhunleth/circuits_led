defmodule CircuitsLED.GPIOServer do
  use GenServer

  alias Circuits.GPIO

  def start_link(pin) do
    GenServer.start_link(__MODULE__, pin, name: pin_to_atom(pin))
  end

  def on(pid) do
    GenServer.call(pid, :on)
  end

  def off(pid) do
    GenServer.call(pid, :off)
  end

  def blink(pid, duration, count) do
    Process.send_after(pid, {:blink, duration, count}, duration)
  end

  def toggle(pid) do
    GenServer.call(pid, :toggle)
  end

  @impl true
  def init(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    {:ok, %{gpio: gpio, status: :off, ref: nil, count: nil}}
  end

  @impl true
  def handle_call(:on, _from, state) do
    GPIO.write(state.gpio, 1)
    state = %{state | status: :on}
    {:reply, :on, state}
  end

  @impl true
  def handle_call(:off, _from, state) do
    GPIO.close(state.gpio)
    state = %{state | status: :off}
    {:reply, :off, state}
  end

  @impl true
  def handle_call(:toggle, _from, state = %{status: :off}) do
    GPIO.write(state.gpio, 1)
    state = %{state | status: :on}
    {:reply, :on, state}
  end

  @impl true
  def handle_call(:toggle, _from, state = %{status: :on}) do
    GPIO.write(state.gpio, 0)
    state = %{state | status: :off}
    {:reply, :off, state}
  end

  @impl true
  def handle_info({:blink, _duration, _count}, state = %{status: :off, count: 0}) do
    GPIO.write(state.gpio, 0)

    {:noreply, state}
  end

  @impl true
  def handle_info({:blink, duration, count}, state = %{status: :off}) do
    GPIO.write(state.gpio, 1)
    ref = Process.send_after(self(), {:blink, duration, count}, duration)

    state = %{state | status: :on, ref: ref, count: count}
    {:noreply, state}
  end

  @impl true
  def handle_info({:blink, duration, count}, state = %{status: :on}) do
    GPIO.write(state.gpio, 0)
    count = count - 1
    ref = Process.send_after(self(), {:blink, duration, count}, duration)

    state = %{state | status: :off, ref: ref, count: count}
    {:noreply, state}
  end

  defp pin_to_atom(pin) do
    pin
    |> Integer.to_string()
    |> String.to_atom()
  end
end
