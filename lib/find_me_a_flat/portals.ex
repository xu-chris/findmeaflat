defmodule FindMeAFlat.Portals do
  @moduledoc """
  The portals themselves and their health. No rows yet; S2 gave it its parsing.

  A persistence domain: it owns rows, never processes. The adapters that parse each
  portal are behaviour implementations under `FindMeAFlat.Portals.Adapter`, and the
  processes that pace requests live in `FindMeAFlat.Fetching`.
  """

  use Ash.Domain,
    otp_app: :find_me_a_flat

  alias FindMeAFlat.Portals.Adapter
  alias FindMeAFlat.Portals.Extraction
  alias FindMeAFlat.Portals.Extractor

  resources do
  end

  @doc """
  Reads a portal response body with the adapter belonging to `slug`.

  Pure: no fetching, no storing, no clock. Fetching is `FindMeAFlat.Fetching`'s
  and storing is `FindMeAFlat.Listings`'s, so the same body parses identically in
  a test, in a crawl and in the drift job.

      {:ok, %Extraction{}}         cards were found; some may have failed
      {:ok, :no_results}           a results page holding no advertisements
      {:error, :unrecognisable}    a body that is not this portal's results page
      {:error, :unknown_portal}    no adapter answers to that slug
  """
  @spec parse(Adapter.slug(), String.t()) ::
          {:ok, Extraction.t()}
          | {:ok, :no_results}
          | {:error, :unrecognisable}
          | {:error, :unknown_portal}
  def parse(slug, html) do
    with {:ok, adapter} <- Adapter.resolve(slug) do
      Extractor.extract(html, adapter)
    end
  end
end
