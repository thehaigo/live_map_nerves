defmodule GpsLogger.Nmea do
  def parse(data) do
    data
    |> String.split(",")
    |> to_gps_struct()
  end

  defp to_gps_struct([
      "$GPGGA", time, latitude, latitude_cardinal,
      longitude, longitude_cardinal, _type, _nb_satellites, _percision,
      _altitude,_altitude_unit, _, _, _, _sig
    ] = data) do
      parse_data(latitude, latitude_cardinal, longitude, longitude_cardinal, time, data)
  end

  defp to_gps_struct([
      "$GPRMC", time, _data_state, latitude, latitude_cardinal,
      longitude, longitude_cardinal, _speed, _, _, _, _, _sig
    ] = data) do
      parse_data(latitude, latitude_cardinal, longitude, longitude_cardinal, time, data)
  end

  defp to_gps_struct(data) do
    {:error, %{message: "can't parse data", data: Enum.join(data, ",")}}
  end

  defp parse_data(lat, lat_cardinal, lng, lng_cardinal, time, data) do
    with {:ok, latitude} <- to_degres("#{lat},#{lat_cardinal}"),
         {:ok, longitude} <- to_degres("#{lng},#{lng_cardinal}") do
      {:ok, %{time: time, lat: latitude, lng: longitude}}
    else
      {:error, %{message: "empty data"}} ->
        {:error, %{message: "empty data", data: Enum.join(data, ",")}}
      _ ->
        {:error, %{message: "can't parse data", data: Enum.join(data, ",")}}
    end
  end

  def to_degres(
    <<degres::bytes-size(2)>> <>
    <<minutes::bytes-size(7)>> <>
    <<_sep::bytes-size(1)>> <>
    <<cardinal::bytes-size(1)>>
  ) do
    {:ok, do_to_degres(degres, minutes, cardinal)}
  end

  def to_degres(
    <<degres::bytes-size(3)>> <>
    <<minutes::bytes-size(6)>> <>
    <<_sep::bytes-size(1)>> <>
    <<cardinal::bytes-size(1)>>
  ) do
    {:ok, do_to_degres(degres, minutes, cardinal)}
  end

  def to_degres(
    <<degres::bytes-size(3)>> <>
    <<minutes::bytes-size(7)>> <>
    <<_sep::bytes-size(1)>> <>
    <<cardinal::bytes-size(1)>>
  ) do
    {:ok, do_to_degres(degres, minutes, cardinal)}
  end

  def to_degres(",") do
    {:error, %{message: "empty data"}}
  end

  defp do_to_degres(degres, minutes, cardinal) do
    degres = degres |> float_parse()
    minutes = minutes |> float_parse()
    (degres + minutes / 60) |> Float.round(5) |> with_cardinal_orientation(cardinal)
  end

  defp with_cardinal_orientation(degres, cardinal) when cardinal in ["N", "E"] do
    degres
  end

  defp with_cardinal_orientation(degres, cardinal) when cardinal in ["S", "W"] do
    -degres
  end

  defp float_parse(value) do
    {value_parsed, _} = Float.parse(value)
    value_parsed
  end
end
