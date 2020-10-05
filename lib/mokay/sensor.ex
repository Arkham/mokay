defmodule Mokay.Sensor do
  use GenServer

  @update_interval 1_000
  @i2c_device "i2c-1"
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
    {:ok, sensor} = BMP280.start_link(bus_name: @i2c_device, bus_address: @i2c_address)
    Process.send_after(self(), :read_sensor, 0)
    {:ok, %{sensor: sensor, temperature: 0, humidity: 0}}
  end

  def handle_info(:read_sensor, %{sensor: sensor} = state) do
    new_state =
      case BMP280.read(sensor) do
        {:ok, %BMP280.Measurement{humidity_rh: h, temperature_c: t}} ->
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
