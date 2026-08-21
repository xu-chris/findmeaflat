defmodule FindMeAFlat.Portals.Adapter.Kleinanzeigen do
  @moduledoc """
  Reads a kleinanzeigen search results page.

  Ported from `.references/lib/sources/kleinanzeigen.js` and corrected against the
  page captured on 2026-08-20. Three of that file's selectors no longer match, so
  "change the domain, that is the whole fix" was optimistic:

    * price moved from `.aditem-main--middle--price` to
      `.aditem-main--middle--price-shipping--price`. The old class survives only as
      a prefix of the new ones, which is why a substring grep said it was fine.
    * size and rooms left `.aditem-main--bottom p span:nth-child(1|2)` -- which now
      holds "Von Privat" or nothing -- for one `.aditem-main--middle--tags`
      paragraph reading "89,14 m2 - 3 Zi.".

  The container needs `article.aditem` and not just `.ad-listitem`: six of the 33
  list items on the captured page are empty advertising slots, and an empty slot
  is not a card that failed.
  """

  @behaviour FindMeAFlat.Portals.Adapter

  @base_url "https://www.kleinanzeigen.de"

  # `body#srchrslt` is set by the page type, so it survives a search that matches
  # nothing -- which is exactly the case that must not read as unrecognisable.
  @results_markers ["body#srchrslt", "#srchrslt-adtable"]
  @card_selector "#srchrslt-adtable .ad-listitem article.aditem"

  @id_attribute "data-adid"
  @link_selector ".aditem-main .text-module-begin a"
  @price_selector ".aditem-main--middle--price-shipping--price"
  @description_selector ".aditem-main--middle--description"
  @address_selector ".aditem-main--top--left"
  @tags_selector ".aditem-main--middle--tags"
  @image_selector ".aditem-image img"

  # "2.585 EUR", "990 EUR VB", "1.234,56 EUR": German thousands dots, an optional
  # decimal comma, and any suffix the seller felt like adding.
  @price ~r/(?<euros>\d{1,3}(?:\.\d{3})*|\d+)(?:,(?<cents>\d{1,2}))?/
  @size ~r/(?<number>[\d.,]+)\s*m²/u
  @rooms ~r/(?<number>[\d.,]+)\s*Zi\./u

  @impl true
  def results_markers, do: @results_markers

  @impl true
  def card_selector, do: @card_selector

  @impl true
  def extract_card(card) do
    tags = text(card, @tags_selector)

    %{
      external_id: card |> Floki.attribute(@id_attribute) |> first(),
      url: card |> Floki.attribute(@link_selector, "href") |> first() |> absolute(),
      title: text(card, @link_selector),
      price_cents: card |> text(@price_selector) |> price_cents(),
      description: text(card, @description_selector),
      address: text(card, @address_selector),
      image_urls: card |> Floki.attribute(@image_selector, "src") |> Enum.uniq(),
      size_sqm: number(tags, @size),
      rooms: number(tags, @rooms)
    }
  end

  defp text(card, selector) do
    card
    |> Floki.find(selector)
    |> Floki.text()
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> presence()
  end

  defp presence(""), do: nil
  defp presence(text), do: text

  defp first([]), do: nil
  defp first([value | _rest]), do: presence(String.trim(value))

  defp absolute(nil), do: nil
  defp absolute("/" <> path), do: @base_url <> "/" <> path
  defp absolute(url), do: url

  defp price_cents(nil), do: nil

  defp price_cents(text) do
    case Regex.named_captures(@price, text) do
      %{"euros" => euros, "cents" => cents} -> to_cents(euros, cents)
      nil -> nil
    end
  end

  defp to_cents(euros, cents) do
    euros = euros |> String.replace(".", "") |> String.to_integer()

    euros * 100 + subunit(cents)
  end

  defp subunit(""), do: 0
  defp subunit(<<tenths>>), do: String.to_integer(<<tenths>>) * 10
  defp subunit(cents), do: String.to_integer(cents)

  defp number(nil, _pattern), do: nil

  defp number(text, pattern) do
    with %{"number" => german} <- Regex.named_captures(pattern, text),
         {number, ""} <-
           german |> String.replace(".", "") |> String.replace(",", ".") |> Decimal.parse() do
      number
    else
      _unreadable -> nil
    end
  end
end
