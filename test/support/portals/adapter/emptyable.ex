defmodule FindMeAFlat.Portals.Adapter.Emptyable do
  @moduledoc """
  Test-only adapter that declares an empty-state marker.

  Exists to prove the `{:ok, :no_results}` branch is reachable at all. No real
  portal adapter can currently demonstrate it: an empty-results page has not been
  captured from any of the four, and until one is, every real adapter returns `[]`
  from `empty_markers/0` and answers zero cards with `{:error, :unrecognisable}`.
  """
  @behaviour FindMeAFlat.Portals.Adapter

  @impl true
  def results_markers, do: ["body#srchrslt"]

  @impl true
  def card_selector, do: "#srchrslt-adtable .ad-listitem article.aditem"

  @impl true
  def empty_markers, do: [".no-results-here"]

  @impl true
  def extract_card(_node), do: %{}
end
