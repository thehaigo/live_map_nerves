defmodule GpsLogger.AuthToken do
  use GenServer
  @name __MODULE__

  def start_link(props) do
    GenServer.start_link(@name, props, name: @name)
  end

  def fetch() do
    GenServer.call(@name, :fetch)
  end

  @impl true
  def init(token: token, endpoint: endpoint) do
    fetch_token(token, endpoint)
    {:ok, {token, endpoint}}
  end

  @impl true
  def handle_call(:fetch, _from, props = {token, endpoint}) do
    case :ets.lookup(:gps, :token)[:token] do
      nil ->
        {:reply, fetch_token(token, endpoint), props}
      jwt ->
        {:reply, jwt, props}
    end
  end

  def fetch_token(token, endpoint) do
    body = Jason.encode!(%{token: token})
    case HTTPoison.post(endpoint, body, %{"Content-Type": "application/json"}) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Jason.decode!(body)
        |> Map.get("token")
        |> tap(&:ets.insert(:gps, {:token, &1}))
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        "Not found :("
      {:ok, %HTTPoison.Response{status_code: 500}} ->
        "invalid token"
      {:error, %HTTPoison.Error{reason: reason}} ->
        reason
    end
  end
end
