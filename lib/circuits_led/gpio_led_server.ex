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
    GenServer.call(pid, {:blink, duration, count})
  end

  def toggle(pid) do
    GenServer.call(pid, :toggle)
  end

  @impl true
  def init(pin) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    {:ok, %{gpio: gpio, blink_ref: nil, status: :off, count: nil, duration: 0}}
  end

  @impl true
  def handle_call(:on, _from, state) do
    GPIO.write(state.gpio, 1)
    state = %{state | status: :on, blink_ref: nil}
    {:reply, :on, state}
  end

  @impl true
  def handle_call(:off, _from, state) do
    GPIO.write(state.gpio, 0)
    state = %{state | status: :off, blink_ref: nil}
    {:reply, :off, state}
  end

  @impl true
  def handle_call(:toggle, _from, state = %{status: :off}) do
    GPIO.write(state.gpio, 1)
    state = %{state | status: :on, blink_ref: nil}
    {:reply, :on, state}
  end

  @impl true
  def handle_call(:toggle, _from, state = %{status: :on}) do
    GPIO.write(state.gpio, 0)
    state = %{state | status: :off, blink_ref: nil}
    {:reply, :off, state}
  end

  @impl true
  def handle_call({:blink, duration, count}, _from, state) do
    GPIO.write(state.gpio, 1)

    blink_ref = make_ref()
    Process.send_after(self(), {:blink_tick, blink_ref}, duration)

    state = %{state | status: :on, blink_ref: blink_ref, count: count - 1, duration: duration}
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:blink_tick, blink_ref}, state = %{blink_ref: blink_ref, count: 0}) do
    GPIO.write(state.gpio, 0)

    {:noreply, %{state | blink_ref: nil}}
  end

  @impl true
  def handle_info({:blink_tick, blink_ref}, state = %{blink_ref: blink_ref, status: :on}) do
    GPIO.write(state.gpio, 0)
    Process.send_after(self(), {:blink_tick, blink_ref}, state.duration)

    state = %{state | status: :off}
    {:noreply, state}
  end

  @impl true
  def handle_info({:blink_tick, blink_ref}, state = %{blink_ref: blink_ref, status: :off}) do
    GPIO.write(state.gpio, 1)
    Process.send_after(self(), {:blink_tick, blink_ref}, state.duration)

    state = %{state | status: :on, count: state.count - 1}
    {:noreply, state}
  end

  @impl true
  def handle_info({:blink_tick, _blink_ref}, state) do
    {:noreply, state}
  end

  defp pin_to_atom(pin) do
    pin
    |> Integer.to_string()
    |> String.to_atom()
  end
end
