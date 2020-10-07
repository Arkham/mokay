defmodule Mokay.Sensor do
  use GenServer

  @update_interval 500
  @i2c_device 1
  @i2c_address 0x76

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def temperature() do
    GenServer.call(__MODULE__, :temperature)
  end

  def humidity() do
    GenServer.call(__MODULE__, :humidity)
  end

  def init(_) do
    {:ok, sensor} = Bme280.start_link(i2c_device_number: @i2c_device, i2c_address: @i2c_address)
    Process.send_after(self(), :read_sensor, 0)
    {:ok, %{sensor: sensor, temperature: 0, humidity: 0}}
  end

  def handle_info(:read_sensor, %{sensor: sensor} = state) do
    new_state =
      case Bme280.measure(sensor) do
        %Bme280.Measurement{humidity: h, temperature: t} ->
          %{state | humidity: h, temperature: t}

        _ ->
          state
      end

    Process.send_after(self(), :read_sensor, @update_interval)
    {:noreply, new_state}
  end

  def handle_call(:humidity, _, state) do
    {:reply, state.humidity, state}
  end

  def handle_call(:temperature, _, state) do
    {:reply, state.temperature, state}
  end
end
