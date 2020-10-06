defmodule Mokay.Server do
  @moduledoc """
  <pre>
              ┌────────────────Giving up────────────┐┌──Retry──┐
              │                                     ││         │
              ▼                                     │▼         │
     ┌────────────────┐                    ┌────────────────┐  │
     │                │                    │                │  │
     │      Idle      │◀───────SMS sent────│  Sending SMS   │──┘
     │                │                    │                │
     └────────────────┘                    └────────────────┘
              │                                     ▲
              │                                     │
              │                                     │
     Button pressed                                 │
              │                                     │
              ▼                                     │
     ┌────────────────┐                             │
     │                │                             │
     │    Checking    │                             │
  ┌──│    Humidity    │──────Humidity level ────────┘
  │  │                │◀─┐       reached
  │  └────────────────┘  │
  │                      │
  └──────────────────────┘
      Humidity level
            low
  </pre>
  """

  use GenServer

  @humidity_difference 15.0
  @humidity_interval 500
  @sms_interval 1_000
  @sms_retries 5

  # Public API

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def button_pressed() do
    GenServer.cast(__MODULE__, :button_pressed)
  end

  # Internals

  @doc """
  Possible states:

  - :idle
  - {:checking_humidity, initial_humidity}
  - {:sending_sms, retries}
  """
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
      {:noreply, %{state | status: {:sending_sms, 0}}}
    else
      Process.send_after(self(), :check_humidity, @humidity_interval)
      {:noreply, state}
    end
  end

  def handle_info(:send_sms, %{status: {:sending_sms, retries}} = state)
      when retries <= @sms_retries do
    case send_sms() do
      {:ok, _} ->
        {:noreply, %{state | status: :idle}}

      {:error, reason} ->
        IO.puts(reason)
        Process.send_after(self(), :send_sms, @sms_interval)
        {:noreply, %{state | status: {:sending_sms, retries + 1}}}
    end
  end

  def handle_info(:send_sms, %{status: {:sending_sms, _}} = state) do
    {:noreply, %{state | status: :idle}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Helpers

  defp get_humidity(), do: Mokay.Sensor.humidity()

  defp send_sms() do
    config = Mokay.Application.config()
    Mokay.SMS.send(config.twilio)
  end
end
