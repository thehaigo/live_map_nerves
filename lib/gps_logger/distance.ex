defmodule GpsLogger.Distance do
  require Logger
  def compute(%{longitude: x1, latitude: y1}, %{longitude: x2, latitude: y2}) do
    distance =
      (:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
      |> :math.sqrt()
      |> Float.ceil(5)
    {:ok, distance}
  end

  def compute(_pos1, _pos2), do: :error

  def to_meters(distance) do
    distance_in_meters = (distance * 111_319.0) |> Float.ceil(5)

    {:ok, distance_in_meters}
  end
end
