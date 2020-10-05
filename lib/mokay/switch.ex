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

  def handle_info({:circuits_gpio, @gpio_pin, _timestamp, 1}, state) do
    Mokay.Server.button_pressed()
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
