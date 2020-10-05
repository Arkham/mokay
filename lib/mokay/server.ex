defmodule Mokay.Server do
  @moduledoc """
  <pre>
     ┌────────────────┐                       ┌────────────────┐
     │                │                       │                │
     │      Idle      │◀───────SMS sent───────│  Sending SMS   │
     │                │                       │                │
     └────────────────┘                       └────────────────┘
              │                                        ▲
              │                                        │
              │                                        │
     Button pressed                                    │
              │                                        │
              │                                        │
              ▼                                        │
     ┌────────────────┐                                │
     │                │                                │
     │    Checking    │      Humidity level            │
  ┌──│    Humidity    │◀─┬───────reached───────────────┘
  │  │                │  │
  │  └────────────────┘  │
  │                      │
  └───Humidity level ────┘
            low
  </pre>
  """

  use GenServer

  @humidity_difference 15.0
  @humidity_interval 500

  # Public API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def button_pressed() do
    GenServer.cast(__MODULE__, :button_pressed)
  end

  # Internals

  def init(_) do
    {:ok, %{status: :idle}}
  end

  def handle_cast(:button_pressed, %{status: :idle} = state) do
    IO.puts("BUTTON PRESSED")
    send(self(), :check_humidity)
    initial_humidity = get_humidity()
    {:noreply, %{state | status: {:checking_humidity, initial_humidity}}}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(:check_humidity, %{status: {:checking_humidity, initial_humidity}} = state) do
    if get_humidity() - initial_humidity > @humidity_difference do
      send(self(), :send_sms)
    else
      Process.send_after(self(), :check_humidity, @humidity_interval)
    end

    {:noreply, state}
  end

  def handle_info(:send_sms, %{status: {:checking_humidity, _}} = state) do
    IO.puts("SENDING SMS")
    Process.send_after(self(), :sms_sent, 5_000)
    {:noreply, %{state | status: :sending_sms}}
  end

  def handle_info(:sms_sent, %{status: :sending_sms} = state) do
    IO.puts("SMS SENT!")
    {:noreply, %{state | status: :idle}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Helpers

  defp get_humidity(), do: Mokay.Sensor.humidity()
end
