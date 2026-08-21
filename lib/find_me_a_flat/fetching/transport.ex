defmodule FindMeAFlat.Fetching.Transport do
  @moduledoc """
  The one seam in this application that tests are allowed to double.

  It is deliberately generic -- a `get` over a URL, nothing portal-shaped. Everything
  a portal needs to see (the header set, the cookie jar, which outcome a status and a
  body add up to) lives in `FindMeAFlat.Fetching`, so a double replaces the network
  and not our own translation.

  There is no `Fetcher` behaviour above this one. That was cut: it had a single
  implementation, and the deferred browser tier for ImmoScout24 is
  "a small sidecar service called over HTTP" (`STACK.md` §3) -- a second *transport*,
  not a second fetcher.

  Implementations normalise their own failures. `{:error, :timeout}` is the one
  reason with a meaning of its own, because it is the one worth retrying on its own
  terms; any other term is a transport failure and `Fetching` says so.
  """

  @type response :: %{
          status: pos_integer(),
          headers: %{String.t() => [String.t()]},
          body: String.t(),
          final_url: String.t()
        }

  @doc """
  Performs one GET. `opts` carries `:headers` as a list of `{name, value}` pairs;
  timeouts, pooling and redirect policy belong to the implementation.
  """
  @callback get(url :: String.t(), opts :: keyword()) ::
              {:ok, response()} | {:error, :timeout} | {:error, term()}
end
