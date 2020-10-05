defmodule Mokay.Switch do
  use GenServer

  @gpio_pin 6

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, gpio} = Circuits.GPIO.open(@gpio_pin, :input, pull_mode: :pulldown)
    Circuits.GPIO.set_interrupts(gpio, :both)
    {:ok, %{gpio: gpio}}
  end

  def handle_info({:circuits_gpio, pin, _timestamp, value}, state) do
    IO.puts("Pin #{pin} switched to #{value}")
    {:noreply, state}
  end
end
