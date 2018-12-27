defmodule PointPolygonBench do
  use Benchfella
  import Topo

  @values -1..13
  @points (for x <- @values, y <- @values, do: %Geo.Point{coordinates: {x, y}})
  @multipoint %Geo.MultiPoint{coordinates: (for x <- @values, y <- @values, do: {x, y})}
  @polygon Path.join([ "test", "fixtures", "poly.geo.json" ])
    |> File.read!
    |> Jason.decode!
    |> Geo.JSON.decode!

  bench "Point / Polygon intersects" do
    Enum.each @points, fn point ->
      intersects? point, @polygon
    end
  end

  bench "Point inside Polygon" do
    intersects? {6, 7}, @polygon
  end

  bench "Point on vertex of Polygon" do
    intersects? {5, 7}, @polygon
  end

  bench "Point on edge of Polygon" do
    intersects? {5.5, 6.5}, @polygon
  end

  bench "Point outside of Polygon" do
    intersects? {5.5, 7}, @polygon
  end

  bench "Point way outside of Polygon" do
    intersects? {25, 37}, @polygon
  end

  bench "Point way outside of Polygon with envelope check" do
    case Envelope.contains?(Envelope.from_geo(@polygon), {25, 37}) do
      true -> Topo.intersects?(@polygon, {25, 37})
      false -> false
    end
  end

  bench "MultiPoint / Polygon intersects" do
    intersects? @multipoint, @polygon
  end

  bench "Polygon / MultiPoint contains" do
    contains? @polygon, @multipoint
  end

  @states Path.join([ "bench", "shapes", "states.json" ])
    |> File.read!
    |> Jason.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode!/1)

  @cities Path.join([ "bench", "shapes", "cities.json" ])
    |> File.read!
    |> Jason.decode!
    |> Map.fetch!("features")
    |> Enum.map(&(&1["geometry"]))
    |> Enum.map(&Geo.JSON.decode!/1)

  bench "Cities in States" do
    [state] = Enum.take_random(@states, 1)
    [city] = Enum.take_random(@cities, 1)
    Topo.contains?(state, city)
    :ok
  end

  bench "Cities in States with Envelope check" do
    [state] = Enum.take_random(@states, 1)
    [%{coordinates: {lon, lat}}] = Enum.take_random(@cities, 1)
    case Envelope.contains?(Envelope.from_geo(state), {lon, lat}) do
      true -> Topo.contains?(state, {lon, lat})
      false -> false
    end
    :ok
  end
end
