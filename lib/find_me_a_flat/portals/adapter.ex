defmodule FindMeAFlat.Portals.Adapter do
  @moduledoc """
  What every portal adapter must answer, and how a slug finds one.

  Resolution is by convention, not by a table: `"kleinanzeigen"` resolves to
  `FindMeAFlat.Portals.Adapter.Kleinanzeigen`, `"wg_gesucht"` to
  `FindMeAFlat.Portals.Adapter.WgGesucht`. Adding a portal adds files and edits no
  shared map, which is what lets the remaining adapters be written in parallel.

  Selectors live in the adapters as module attributes rather than in database
  rows. Of the four portals in scope exactly one is expressible as selector plus
  attribute plus cast, so a row format would cover one portal in four -- and rows
  would put production parsing behaviour outside git, where no review, no local
  reproduction and no "which selector parsed this listing" is possible.
  """

  @typedoc "A portal's slug, as stored on the `Portal` row."
  @type slug :: String.t() | atom()

  @doc """
  Selectors that say "this is our results page".

  Any one matching is enough. A body where none match is not an empty result set;
  it is a page we cannot read -- a challenge, an error page, a redesign -- and
  telling those apart is the whole point of the three page classes.
  """
  @callback results_markers() :: [String.t()]

  @doc "The selector matching one advertisement node, banner slots excluded."
  @callback card_selector() :: String.t()

  @doc """
  Selectors that positively prove a page is an *empty* result set.

  Zero cards is not evidence of emptiness. A portal that keeps its page shell and
  renames the card container yields zero cards on a perfectly healthy 200 — and if
  that returned `:no_results`, portal health could never tell a silent breakage
  from a narrow search. So emptiness must be asserted by the page, not inferred
  from the absence of cards.

  An adapter that cannot yet identify its portal's empty state returns `[]`, which
  makes zero cards `{:error, :unrecognisable}` — loud and wrong-in-the-safe-direction,
  rather than quiet and wrong-in-the-dangerous-one.
  """
  @callback empty_markers() :: [String.t()]

  @doc """
  Reads one advertisement node into `FindMeAFlat.Portals.Card` fields.

  Return what the node carried and `nil` for what it did not. Raising is allowed
  and costs only that card, but a field that is merely absent should be `nil`, so
  it lands in the fill rates instead of the error count.
  """
  @callback extract_card(Floki.html_node()) :: %{atom() => term()}

  @doc "The adapter answering to `slug`, or `{:error, :unknown_portal}`."
  @spec resolve(slug()) :: {:ok, module()} | {:error, :unknown_portal}
  def resolve(slug) do
    module = Module.concat(__MODULE__, Macro.camelize(to_string(slug)))

    if adapter?(module), do: {:ok, module}, else: {:error, :unknown_portal}
  end

  defp adapter?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :extract_card, 1)
  end
end
