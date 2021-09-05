defmodule GpsLogger.DataFetcher do
  use GenServer
  @name __MODULE__

  @doc """
  Start the fetcher and open communication with GPS card.
  """
  def start_link(state \\ []) do
    GenServer.start_link(@name, state, name: @name)
  end

  @impl true
  def init(_state) do
    [{uart, nil}] = Registry.lookup(GpsLogger.Registry, "uart")
    Circuits.UART.configure(uart, framing: {Circuits.UART.Framing.Line, separator: "\r\n"})
    Circuits.UART.open(uart, "ttyAMA0", speed: 9600, active: true)

    {:ok, %{current_position: nil}}
  end

  @impl true
  def handle_info({:circuits_uart, port, data}, state) do
    receive_data({:circuits_uart, port, data}, state)
  end

  def receive_data({:circuits_uart, _port, data}, state) do
    state =
      case GpsLogger.Nmea.parse(data) do
        {:ok, position} ->
          GpsLogger.Transpondeur.emit(position)
          %{current_position: position}
        _ ->
          state
      end
    {:noreply, state}
  end
end
