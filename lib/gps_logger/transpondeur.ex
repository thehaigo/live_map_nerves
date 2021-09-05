defmodule GpsLogger.Transpondeur do
  use GenServer

  @name __MODULE__

  def start_link(endpoint) do
    GenServer.start_link(@name, endpoint, name: @name)
  end

  def emit(coordinates) do
    GenServer.cast(@name, {:emit, coordinates})
  end

  @impl true
  def init(endpoint) do
    {:ok, %{endpoint: endpoint, current_position: nil}}
  end

  @impl true
  def handle_cast({:emit, position}, state = %{endpoint: endpoint, current_position: nil}) do
    post_to(endpoint, position)

    {:noreply, %{state | current_position: position}}
  end

  def handle_cast({:emit, position}, state = %{endpoint: endpoint, current_position: current_position}) do
    with true <- position_issued_after?(position, current_position),
      {:ok, distance} <- GpsLogger.Distance.compute(position, current_position),
      {:ok, distance_in_meters} <- GpsLogger.Distance.to_meters(distance),
      true <- distance_in_meters > 5.0
    do
      post_to(endpoint, position)
      {:noreply, %{state | current_position: position }}
    else
      _ ->
        {:noreply, state}
    end
  end

  def position_issued_after?(position, current_position) do
    with {position_time, ""} <- Float.parse(Map.get(position, :time, "0")),
         {current_position_time, ""} <- Float.parse(Map.get(current_position, :time, "0"))
    do
      position_time > current_position_time
    end
  end

  defp post_to(endpoint, position) do
    token = GpsLogger.AuthToken.fetch()
    map = GpsLogger.FetchMap.fetch()
    {:ok, json} = position |> Map.put(:map_id, map) |> Jason.encode()
    HTTPoison.post(endpoint,
      json,
      %{
        "User-Agent": "GPSLogger",
        "Content-Type": "application/json",
        "Authorization": "Bearer: #{token}"
      }
    )
  end
end
