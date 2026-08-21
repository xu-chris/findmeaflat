defmodule FindMeAFlat.Portals.Extractor do
  @moduledoc """
  Turns one portal response body into cards, errors and fill rates.

  A pure function of the body: no database, no network, no clock. Everything
  portal-specific is the adapter's; everything here is the part that must behave
  identically for all four portals.

  Three page classes, because "nothing new", "genuinely no results" and "we cannot
  read this page" are three different facts and one integer carried none of them:

    * `{:ok, %Extraction{}}` -- card nodes were found, and each one either parsed
      or was counted as an error
    * `{:ok, :no_results}` -- the page is recognisably the portal's results page
      and holds no advertisements
    * `{:error, :unrecognisable}` -- nothing on the page says it is a results page
  """

  alias FindMeAFlat.Portals.Card
  alias FindMeAFlat.Portals.Extraction
  alias FindMeAFlat.Portals.Extraction.CardError

  require Logger

  # Without these two a card cannot be deduplicated or opened, so it is not a
  # listing at all. Everything else missing is a fill-rate question.
  @identity [:external_id, :url]

  @doc "Reads `html` with `adapter`."
  @spec extract(String.t(), module()) ::
          {:ok, Extraction.t()} | {:ok, :no_results} | {:error, :unrecognisable}
  def extract(html, adapter) when is_binary(html) do
    with {:ok, document} <- parse_document(html),
         :ok <- recognise(document, adapter) do
      document |> Floki.find(adapter.card_selector()) |> read_cards(adapter)
    end
  end

  defp parse_document(html) do
    case Floki.parse_document(html) do
      {:ok, document} -> {:ok, document}
      {:error, _reason} -> {:error, :unrecognisable}
    end
  end

  defp recognise(document, adapter) do
    if Enum.any?(adapter.results_markers(), &(Floki.find(document, &1) != [])) do
      :ok
    else
      {:error, :unrecognisable}
    end
  end

  defp read_cards([], _adapter), do: {:ok, :no_results}

  defp read_cards(nodes, adapter) do
    {read, failed} =
      nodes
      |> Enum.map(&read_card(&1, adapter))
      |> Enum.split_with(&match?({:ok, _card}, &1))

    {:ok, Extraction.new(Enum.map(read, &elem(&1, 1)), Enum.map(failed, &elem(&1, 1)))}
  end

  defp read_card(node, adapter) do
    card = struct!(Card, adapter.extract_card(node))
    filled = Card.filled_fields(card)

    case Enum.reject(@identity, &MapSet.member?(filled, &1)) do
      [] -> {:ok, card}
      missing -> {:error, CardError.new(:missing_identity, missing, node)}
    end
  rescue
    error ->
      # One card blowing up must cost that card and no other: the predecessor
      # rejected whole batches over a single unexpected price format.
      Logger.warning("#{inspect(adapter)} raised reading a card: #{Exception.message(error)}")
      {:error, CardError.new(:adapter_raised, Exception.message(error), node)}
  end
end
