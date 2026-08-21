defmodule FindMeAFlat.Fetching.Transport.Req do
  @moduledoc """
  The plain-HTTP transport: `Req` over the named `FindMeAFlat.Finch` pool.

  HTTP/2 first, falling back to HTTP/1.1, because a client that negotiates only
  HTTP/1.1 while claiming to be Chrome contradicts itself in the first packet, and
  connection reuse is the cheapest politeness there is.

  Redirects are followed, which is not optional here: Immonet's URLs redirect twice
  before landing anywhere. The final URL is recorded as a response step appended
  after Req's own redirect step, so what comes back is the URL the chain ended on
  rather than the one we asked for.

  Timeouts are the transport's business, and it normalises them: `{:error, :timeout}`
  is a distinct answer, everything else is handed up as-is for `Fetching` to call a
  transport error. The *connect* timeout is not set here: Req refuses `:connect_options`
  alongside a named `:finch` pool, because connecting is the pool's job. It lives in
  `FindMeAFlat.Fetching.Supervisor` with the rest of the pool configuration.
  """

  @behaviour FindMeAFlat.Fetching.Transport

  @receive_timeout to_timeout(second: 15)

  @impl FindMeAFlat.Fetching.Transport
  def get(url, opts) do
    [
      url: url,
      headers: Keyword.get(opts, :headers, []),
      finch: [name: FindMeAFlat.Finch],
      redirect: true,
      max_redirects: 5,
      # Req defaults this to false, which would send no `accept-encoding` at all --
      # unusual enough to be a fingerprint, and it costs a megabyte per listing page.
      compressed: true,
      # Portal pages are HTML, and Req only decodes content types it knows anyway.
      # Off, so nothing between here and the parser reshapes a body.
      decode_body: false,
      receive_timeout: @receive_timeout,
      retry: false
    ]
    |> Req.new()
    |> Req.Request.append_response_steps(record_final_url: &record_final_url/1)
    |> Req.request()
    |> translate(url)
  end

  # Runs after Req's redirect step, so on a redirected request it is the redirected
  # request that reaches here.
  defp record_final_url({request, response}) do
    {request, Req.Response.put_private(response, :final_url, URI.to_string(request.url))}
  end

  defp translate({:ok, %Req.Response{} = response}, url) do
    {:ok,
     %{
       status: response.status,
       headers: response.headers,
       body: to_string(response.body),
       final_url: Req.Response.get_private(response, :final_url, url)
     }}
  end

  defp translate({:error, %Req.TransportError{reason: :timeout}}, _url), do: {:error, :timeout}
  defp translate({:error, reason}, _url), do: {:error, reason}
end
