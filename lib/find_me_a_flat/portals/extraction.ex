defmodule FindMeAFlat.Portals.Extraction do
  @moduledoc """
  What one results page produced: the cards, the cards that failed, and how much
  of each card the portal actually filled in.

  Counts alone are a silence generator. A portal that renames its price element
  still yields 27 cards out of 27, no error is raised, no counter moves, and users
  simply stop seeing prices -- the exact shape of the year the predecessor spent
  broken. `fill_rates` is the number that moves in that case, and S13 drives
  portal health off it.
  """

  alias FindMeAFlat.Portals.Card

  defstruct cards: [], card_count: 0, errors: [], error_count: 0, fill_rates: %{}

  @type t :: %__MODULE__{
          cards: [Card.t()],
          card_count: non_neg_integer(),
          errors: [__MODULE__.CardError.t()],
          error_count: non_neg_integer(),
          fill_rates: %{atom() => float()}
        }

  @doc """
  Builds the report for one page from the cards that parsed and the ones that did not.

  Fill rates are measured over the cards that parsed, because that is the
  population the question is about: "of the listings we can read, how many carry
  a price". A page where nothing parsed reports zero everywhere and is told apart
  from an empty page by `error_count`.
  """
  @spec new([Card.t()], [__MODULE__.CardError.t()]) :: t()
  def new(cards, errors) do
    %__MODULE__{
      cards: cards,
      card_count: length(cards),
      errors: errors,
      error_count: length(errors),
      fill_rates: fill_rates(cards)
    }
  end

  defp fill_rates([]), do: Map.new(Card.fields(), &{&1, 0.0})

  defp fill_rates(cards) do
    filled = Enum.map(cards, &Card.filled_fields/1)
    total = length(cards)

    Map.new(Card.fields(), fn field ->
      {field, Float.round(Enum.count(filled, &MapSet.member?(&1, field)) / total, 3)}
    end)
  end

  defmodule CardError do
    @moduledoc """
    One card that did not become a `Card`, and enough of it to repair the adapter.

    `:missing_identity` is a card we cannot deduplicate or link to -- no id, or no
    URL. `:adapter_raised` is a bug in our own selector code. The snippet is the
    first 200 characters of the node, which is what an operator needs to see which
    selector went stale.
    """

    defstruct [:reason, :detail, :snippet]

    @type t :: %__MODULE__{
            reason: :missing_identity | :adapter_raised,
            detail: [atom()] | String.t(),
            snippet: String.t()
          }

    @snippet_length 200

    @doc "Records a failed card together with the markup that failed."
    @spec new(:missing_identity | :adapter_raised, [atom()] | String.t(), Floki.html_node()) ::
            t()
    def new(reason, detail, node) do
      %__MODULE__{
        reason: reason,
        detail: detail,
        snippet: node |> Floki.raw_html() |> String.slice(0, @snippet_length)
      }
    end
  end
end
