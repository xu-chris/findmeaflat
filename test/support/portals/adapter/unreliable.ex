defmodule FindMeAFlat.Portals.Adapter.Unreliable do
  @moduledoc """
  A test-only adapter that raises on any card whose id is not a number.

  It ships in `test/support` and never in a release. It exists because the
  extractor's promise to the adapters written after it -- immowelt,
  immosuchmaschine and wg_gesucht, whose Node ancestors all threw on an
  unexpected price format -- is that a card blowing up costs that card and no
  other. Only an adapter that actually blows up can prove it.
  """

  @behaviour FindMeAFlat.Portals.Adapter

  @impl true
  def results_markers, do: ["#cards"]

  @impl true
  def card_selector, do: "#cards .card"

  @impl true
  def empty_markers, do: []

  @impl true
  def extract_card(card) do
    id = card |> Floki.attribute("data-id") |> List.first()
    number = String.to_integer(id)

    %{external_id: Integer.to_string(number), url: "https://example.test/#{number}"}
  end
end
