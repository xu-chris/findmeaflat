defmodule FindMeAFlat.Portals.ExtractionTest do
  use ExUnit.Case, async: true

  alias FindMeAFlat.PortalFixture
  alias FindMeAFlat.Portals
  alias FindMeAFlat.Portals.Adapter.Emptyable
  alias FindMeAFlat.Portals.Extractor

  describe "the three page classes" do
    test "a results page holding advertisements returns the cards it found" do
      html = PortalFixture.read!("kleinanzeigen_2026_08_20.html")

      assert {:ok, extraction} = Portals.parse("kleinanzeigen", html)
      assert extraction.card_count == 27
      assert extraction.error_count == 0
      assert length(extraction.cards) == 27
    end

    test "zero cards without a proved empty state is :unrecognisable, not :no_results" do
      # This fixture is derived: card nodes deleted, page metadata left claiming
      # thousands of results. That is indistinguishable from a portal renaming its
      # card container — which is the point. Absent a real empty-state marker the
      # only safe answer is the loud one, because a false ":no_results" costs every
      # listing until somebody notices, while a false ":unrecognisable" costs one
      # alert.
      html = PortalFixture.read!("kleinanzeigen_2026_08_20_no_results.html")

      assert {:error, :unrecognisable} = Portals.parse("kleinanzeigen", html)
    end

    test "zero cards WITH a proved empty state is :no_results" do
      # Proves the branch exists and is reachable, using a test adapter that does
      # declare an empty marker. A real kleinanzeigen empty page has not been
      # captured; when one is, its marker goes in the adapter and this becomes a
      # fixture test.
      html = ~s(<html><body id="srchrslt"><div id="srchrslt-adtable"></div>
               <div class="no-results-here">Keine Anzeigen gefunden</div></body></html>)

      assert {:ok, :no_results} =
               Extractor.extract(html, Emptyable)
    end

    test "a bot-challenge body is unrecognisable, not an empty result set" do
      html = PortalFixture.read!("immoscout_2026_08_20_waf_challenge.html")

      assert {:error, :unrecognisable} = Portals.parse("kleinanzeigen", html)
    end
  end

  describe "one card failing" do
    test "is counted as an error and leaves the rest of the page intact" do
      html = PortalFixture.read!("kleinanzeigen_2026_08_20_malformed_card.html")

      assert {:ok, extraction} = Portals.parse("kleinanzeigen", html)
      assert extraction.card_count == 26
      assert extraction.error_count == 1
      assert [%{reason: :missing_identity, detail: [:external_id]}] = extraction.errors
      refute Enum.any?(extraction.cards, &is_nil(&1.external_id))
    end

    @tag :capture_log
    test "costs only that card even when the adapter raises on it" do
      html = """
      <html><body><ul id="cards">
        <li class="card" data-id="1"></li>
        <li class="card" data-id="not-a-number"></li>
        <li class="card" data-id="3"></li>
      </ul></body></html>
      """

      assert {:ok, extraction} = Portals.parse("unreliable", html)
      assert extraction.card_count == 2
      assert extraction.error_count == 1
      assert [%{reason: :adapter_raised}] = extraction.errors
    end
  end

  describe "fill rates" do
    test "report every field filled when the portal's markup is intact" do
      html = PortalFixture.read!("kleinanzeigen_2026_08_20.html")

      assert {:ok, extraction} = Portals.parse("kleinanzeigen", html)

      for field <- [:external_id, :title, :url, :price_cents, :description, :image_urls] do
        assert extraction.fill_rates[field] == 1.0, "#{field} is #{extraction.fill_rates[field]}"
      end
    end

    test "fall to zero for a field the portal stopped emitting, while the cards still parse" do
      # The silence generator: kleinanzeigen renames its price element, every card
      # still parses, every price is nil, and without this number nothing moves.
      html =
        "kleinanzeigen_2026_08_20.html"
        |> PortalFixture.read!()
        |> String.replace(
          "aditem-main--middle--price-shipping--price",
          "aditem-main--middle--rent"
        )

      assert {:ok, extraction} = Portals.parse("kleinanzeigen", html)
      assert extraction.card_count == 27
      assert extraction.error_count == 0
      assert extraction.fill_rates[:price_cents] == 0.0
      assert extraction.fill_rates[:external_id] == 1.0
    end
  end

  describe "resolving a portal to its adapter" do
    test "refuses a slug no adapter answers to" do
      assert {:error, :unknown_portal} = Portals.parse("immonet", "<html></html>")
    end
  end
end
