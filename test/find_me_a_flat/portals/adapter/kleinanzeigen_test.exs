defmodule FindMeAFlat.Portals.Adapter.KleinanzeigenTest do
  use ExUnit.Case, async: true

  alias FindMeAFlat.PortalFixture
  alias FindMeAFlat.Portals

  @fixture "kleinanzeigen_2026_08_20.html"

  # The six a Telegram message cannot be assembled without.
  @needed_to_deliver [:external_id, :title, :url, :price_cents, :description, :image_urls]

  describe "the stored results page" do
    test "yields a listing per advertisement, each carrying every field a delivery needs" do
      {:ok, extraction} = Portals.parse("kleinanzeigen", PortalFixture.read!(@fixture))

      assert length(extraction.cards) >= 25

      empty =
        for card <- extraction.cards,
            field <- @needed_to_deliver,
            Map.fetch!(card, field) in [nil, "", []],
            do: {card.external_id, field}

      assert empty == []
    end

    test "reads a listing exactly as the page prints it" do
      {:ok, extraction} = Portals.parse("kleinanzeigen", PortalFixture.read!(@fixture))

      card = Enum.find(extraction.cards, &(&1.external_id == "3420563465"))

      assert is_struct(card, FindMeAFlat.Portals.Card)
      assert card.title == "Möblierte 3-Raum Wohnung in Berlin Mitte-Wohnen auf Zeit (2Jahre)"

      # The portal serves a root-relative href; a delivered listing needs a link
      # that works outside the portal's own page.
      assert card.url ==
               "https://www.kleinanzeigen.de/s-anzeige/moeblierte-3-raum-wohnung-in-berlin-mitte-wohnen-auf-zeit-2jahre-/3420563465-203-3521"

      # Printed as "2.585 €" -- German thousands separator, euros, not cents.
      assert card.price_cents == 258_500

      assert card.description ==
               "Ab dem 01.09.2026 bis 31.08.2028 vermieten wir eine möblierte Wohnung in zentraler Lage von..."

      assert card.address == "10179 Mitte"

      assert card.image_urls == [
               "https://img.kleinanzeigen.de/api/v1/prod-ads/images/84/840ae8ee-2dbd-43c5-9df6-68400657f932?rule=$_59.AUTO"
             ]

      # Printed as "89,14 m² · 3 Zi.": a German decimal comma, and the two numbers
      # a search filters on.
      assert Decimal.equal?(card.size_sqm, Decimal.new("89.14"))
      assert Decimal.equal?(card.rooms, Decimal.new("3"))
    end

    test "reads a negotiable price as the amount asked" do
      {:ok, extraction} = Portals.parse("kleinanzeigen", PortalFixture.read!(@fixture))

      card = Enum.find(extraction.cards, &(&1.external_id == "3488530104"))

      # Printed as "990 € VB" -- Verhandlungsbasis. The predecessor's
      # immosuchmaschine parser rejected the whole batch over a price suffix.
      assert card.price_cents == 99_000
    end
  end
end
