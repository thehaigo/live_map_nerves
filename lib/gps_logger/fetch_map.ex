defmodule GpsLogger.FetchMap do
  use GenServer
  @name __MODULE__

  def start_link(endpoint) do
    GenServer.start_link(@name, endpoint, name: @name)
  end

  def fetch do
    GenServer.call(@name, :fetch)
  end

  @impl true
  def init(endpoint) do
    fetch_last_map_id(endpoint)
    {:ok, endpoint}
  end

  @impl true
  def handle_call(:fetch, _from, endpoint) do
    case :ets.lookup(:gps, :map_id)[:map_id] do
      nil ->
        {:reply, fetch_last_map_id(endpoint), endpoint}
      map_id ->
        {:reply, map_id, endpoint}
    end
  end

  def fetch_last_map_id(endpoint) do
    token = GpsLogger.AuthToken.fetch()
    header = %{"Content-Type": "application/json", "Authorization": "Bearer: #{token}"}
    case HTTPoison.get(endpoint, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> List.last()
        |> Map.get("id")
        |> tap(&:ets.insert(:gps, {:map_id, &1}))
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "Not found"
      {:ok, %HTTPoison.Response{status_code: 500}} ->
        "invalid token"
      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end
end
