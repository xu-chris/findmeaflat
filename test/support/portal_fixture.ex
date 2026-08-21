defmodule FindMeAFlat.PortalFixture do
  @moduledoc """
  Reads the portal HTML bodies committed under `test/support/fixtures/portals`.

  Every one of them is a real response, captured once and never re-fetched: a test
  that hits a live portal fails on a train, rate-limits a site that is already
  blocking us, and passes for the wrong reason the day the portal answers a
  challenge page with HTTP 200.

  Each fixture has a sibling `.source` file recording where it came from and, for
  the derived ones, exactly what was changed.
  """

  @dir "test/support/fixtures/portals"

  @doc "The committed body of `name`, as the portal sent it."
  @spec read!(String.t()) :: String.t()
  def read!(name), do: @dir |> Path.join(name) |> File.read!()
end
