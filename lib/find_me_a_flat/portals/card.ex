defmodule FindMeAFlat.Portals.Card do
  @moduledoc """
  One advertisement, exactly as a portal's results page printed it.

  Not a `Listing`: nothing here has been stored, deduplicated or matched against a
  search yet. A card is what an adapter could read off one node of one page, and
  a field it could not read is `nil` rather than an error -- a missing price is a
  worse listing, not a broken one. Which fields were readable is the signal
  `Extraction` turns into fill rates, and fill rates are how a portal that quietly
  stopped printing prices gets caught.
  """

  @fields [
    :external_id,
    :url,
    :title,
    :price_cents,
    :description,
    :image_urls,
    :address,
    :size_sqm,
    :rooms
  ]

  defstruct external_id: nil,
            url: nil,
            title: nil,
            price_cents: nil,
            description: nil,
            image_urls: [],
            address: nil,
            size_sqm: nil,
            rooms: nil

  @type t :: %__MODULE__{
          external_id: String.t() | nil,
          url: String.t() | nil,
          title: String.t() | nil,
          price_cents: non_neg_integer() | nil,
          description: String.t() | nil,
          image_urls: [String.t()],
          address: String.t() | nil,
          size_sqm: Decimal.t() | nil,
          rooms: Decimal.t() | nil
        }

  @doc "Every field a card can carry, in the order a report should read them."
  @spec fields() :: [atom()]
  def fields, do: @fields

  @doc """
  The fields this card actually carries.

  Blank is blank however the adapter expressed it: `nil`, an empty string and an
  empty image list all mean the portal did not give us that fact.
  """
  @spec filled_fields(t()) :: MapSet.t(atom())
  def filled_fields(%__MODULE__{} = card) do
    for field <- @fields, filled?(Map.fetch!(card, field)), into: MapSet.new(), do: field
  end

  defp filled?(nil), do: false
  defp filled?(""), do: false
  defp filled?([]), do: false
  defp filled?(_value), do: true
end
