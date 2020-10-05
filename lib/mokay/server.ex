defmodule Mokay.Server do
  use GenServer

  @update_interval 2_000
  @i2c_device "i2c-1"
  @i2c_address 0x76

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, sensor} = BMP280.start_link(bus_name: @i2c_device, bus_address: @i2c_address)
    Process.send_after(self(), :read_sensor, 0)
    {:ok, %{sensor: sensor}}
  end

  def handle_info(:read_sensor, %{sensor: sensor} = state) do
    IO.inspect(BMP280.read(sensor))
    Process.send_after(self(), :read_sensor, @update_interval)
    {:noreply, state}
  end
end
