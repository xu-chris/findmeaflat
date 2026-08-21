defmodule FindMeAFlat.Fetching.Page do
  @moduledoc """
  One portal response that is worth parsing.

  A `Page` only ever exists for a response `FindMeAFlat.Fetching` has already
  decided is a page: not a challenge, not a truncated body, not a 410. Everything
  else is an error value, so nothing downstream has to re-derive "was this real?"
  from a status code.

  `final_url` is the URL the redirect chain ended on, which is not always the one
  we asked for -- Immonet's URLs redirect twice into Immowelt -- and it is what a
  listing's absolute links have to be resolved against.
  """

  @enforce_keys [:url, :final_url, :status, :body, :fetched_at]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          url: String.t(),
          final_url: String.t(),
          status: 200..299,
          body: String.t(),
          fetched_at: DateTime.t()
        }

  @doc "Builds a page from a response the caller has already classified as one."
  @spec new(String.t(), String.t(), 200..299, String.t()) :: t()
  def new(url, final_url, status, body) do
    %__MODULE__{
      url: url,
      final_url: final_url,
      status: status,
      body: body,
      fetched_at: DateTime.utc_now()
    }
  end
end
