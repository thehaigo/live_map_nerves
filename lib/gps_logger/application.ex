defmodule GpsLogger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    :ets.new(:gps, [:set, :public, :named_table])
    opts = [strategy: :one_for_one, name: GpsLogger.Supervisor]
    Supervisor.start_link(children(target()), opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      {GpsLogger.AuthToken, [token: "your live_map setting page's token", endpoint: "http://localhost:4000/api/sign_in"]},
      {GpsLogger.FetchMap, ["http://localhost:4000/api/maps"]},
      {GpsLogger.Transpondeur, ["http://localhost:4000/api/position"]},
    ]
  end

  def children(_target) do
    [
      {Registry,[keys: :unique, name: GpsLogger.Registry]},
      {Circuits.UART, [name: {:via, Registry, {GpsLogger.Registry, "uart"}}]},
      {GpsLogger.AuthToken, [token: "your live_map setting page's token", endpoint: "http://local_ip_address:4000/api/sign_in"]},
      {GpsLogger.FetchMap, ["http://local_ip_address:4000/api/maps"]},
      {GpsLogger.Transpondeur, ["http://local_ip_address:4000/api/points"]},
      {GpsLogger.DataFetcher,[]}
    ]
  end

  def target() do
    Application.get_env(:gps_logger, :target)
  end
end
