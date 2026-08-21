defmodule FindMeAFlat.Fetching.Transport.Stub do
  @moduledoc """
  The one doubled seam in `FindMeAFlat.Fetching`, wired in by `config/test.exs`.

  It replays what a portal would send, keyed only on the request path, and holds no
  state at all. That matters for two reasons. Tests that exercise the gate run their
  fetches inside `Task`s, and a stateless double needs no allowance plumbing to be
  visible from a spawned process. And every response below is a *stored* one: two of
  them are real bodies captured from live probes on 2026-08-20, and nothing in this
  suite touches the network.

  The failure modes here are the ones a live portal will not perform on demand — a
  410, a WAF challenge served under HTTP 200, a body cut off mid-tag, a timeout.
  Those are precisely this project's real failure modes (`CRAWL-DIAGNOSIS.md`).

  `/echo` returns the request headers as the response body, which is how a test
  asserts on the header set and the cookie jar without a recording mechanism.
  """

  @behaviour FindMeAFlat.Fetching.Transport

  @fixtures Path.expand("../fixtures/fetching", __DIR__)
  @aws_waf_path Path.join(@fixtures, "aws_waf_challenge.html")
  @datadome_path Path.join(@fixtures, "datadome_block.html")

  @external_resource @aws_waf_path
  @external_resource @datadome_path

  # ImmoScout24, 2026-08-20: HTTP 401, `Ich bin kein Roboter`, edge.sdk.awswaf.com.
  @aws_waf_challenge File.read!(@aws_waf_path)
  # Immonet -> Immowelt sunset redirect, 2026-08-20: HTTP 403, captcha-delivery.com.
  @datadome_block File.read!(@datadome_path)

  @results_page """
  <html><head><title>Wohnungen mieten</title></head>
  <body><ul class="results"><li>Ein Angebot</li></ul></body></html>
  """

  @host "https://stub.test"

  @doc """
  The base URL every stubbed route hangs off. `.test` is reserved by RFC 6761, so a
  request that escaped the double could never resolve.
  """
  def host, do: @host

  @doc "The stored AWS WAF challenge body, for tests that assert on its markers."
  def aws_waf_challenge, do: @aws_waf_challenge

  @impl FindMeAFlat.Fetching.Transport
  def get(url, opts) do
    url |> URI.parse() |> Map.fetch!(:path) |> respond(url, opts)
  end

  defp respond("/ok", url, _opts), do: {:ok, ok(url, @results_page)}

  defp respond("/slow", url, _opts) do
    announce("/slow")
    Process.sleep(1_000)
    {:ok, ok(url, @results_page)}
  end

  # A challenge the honest way round: the status says "no" and the body says why.
  defp respond("/challenge/aws-waf", url, _opts) do
    {:ok, %{status: 401, headers: %{}, body: @aws_waf_challenge, final_url: url}}
  end

  # The same body under HTTP 200. A portal behind a challenge is free to answer 200,
  # and `CRAWL-DIAGNOSIS.md` records Berlin's WFS doing exactly that with a
  # maintenance page. A 200 is not a success.
  defp respond("/challenge/aws-waf-under-200", url, _opts) do
    {:ok, ok(url, @aws_waf_challenge)}
  end

  # Immonet as probed: two redirects into Immowelt, then DataDome under a 403.
  defp respond("/challenge/datadome", _url, _opts) do
    {:ok,
     %{
       status: 403,
       headers: %{},
       body: @datadome_block,
       final_url: "https://www.immowelt.de/?#x-sunset-redirect=imn"
     }}
  end

  defp respond("/gone", url, _opts),
    do: {:ok, %{status: 410, headers: %{}, body: "", final_url: url}}

  defp respond("/not-found", url, _opts),
    do: {:ok, %{status: 404, headers: %{}, body: "", final_url: url}}

  defp respond("/rate-limited", url, _opts),
    do: {:ok, %{status: 429, headers: %{}, body: "", final_url: url}}

  defp respond("/server-error", url, _opts),
    do: {:ok, %{status: 500, headers: %{}, body: "", final_url: url}}

  # Chunked transfer cut mid-document: a 200, real markup, no closing tag.
  defp respond("/truncated", url, _opts) do
    {:ok, ok(url, "<html><head><title>Wohnungen</title></head><body><ul class=\"resu")}
  end

  defp respond("/redirected", _url, _opts), do: {:ok, ok("#{@host}/ok", @results_page)}

  defp respond("/timeout", _url, _opts), do: {:error, :timeout}

  defp respond("/refused", _url, _opts), do: {:error, :econnrefused}

  defp respond("/set-cookie", url, _opts) do
    {:ok,
     %{
       status: 200,
       headers: %{
         "set-cookie" => [
           "datadome=abc123; Max-Age=31536000; Domain=.stub.test; Path=/; Secure",
           "session=xyz789; Path=/; HttpOnly"
         ]
       },
       body: @results_page,
       final_url: url
     }}
  end

  # Hands the request headers back as the body, so a test can assert on what
  # `Fetching` actually sent without the double having to remember anything.
  defp respond("/echo", url, opts) do
    rendered =
      opts
      |> Keyword.get(:headers, [])
      |> Enum.map_join("\n", fn {name, value} -> "#{name}: #{value}" end)

    {:ok, ok(url, "<html><body><pre>\n#{rendered}\n</pre></body></html>")}
  end

  defp ok(url, body), do: %{status: 200, headers: %{}, body: body, final_url: url}

  # Lets a test know the request is in the double's hands. `Task.async` records the
  # spawning process in `$callers`, which is how a fetch running inside a task
  # reaches the test process that started it.
  defp announce(path) do
    case Process.get(:"$callers") do
      [caller | _] -> send(caller, {:stub, :fetch_started, path})
      _ -> :ok
    end
  end
end
