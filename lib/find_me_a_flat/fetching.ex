defmodule FindMeAFlat.Fetching do
  @moduledoc """
  Asks a portal for a page, and turns what comes back into a value with a decision
  attached.

  The predecessor reported "0 new listings" whether a search was genuinely quiet or
  the portal had returned a 410, and five of six portals stayed broken for months
  behind that one sentence (`CRAWL-DIAGNOSIS.md` §8). So every response leaves here
  as exactly one of seven things, and `disposition/1` says what a worker does about
  each one. Nothing downstream re-derives a decision from a status code.

      {:ok, %Page{}}
      {:error, :challenged}       # cancel -- a bot wall, or a page that is not one
      {:error, :gone}             # cancel -- 410, the URL is retired
      {:error, :not_found}        # cancel -- 404, the URL is wrong
      {:error, :rate_limited}     # snooze -- 429, come back much later
      {:error, :timeout}          # retry
      {:error, :transport_error}  # retry
      {:error, :gated, ms}        # snooze -- our own pacing, not the portal's

  **Cancel is the load-bearing word.** Oban's default `max_attempts` is 20. Retrying
  a challenge means nineteen further requests to a site that is actively telling us
  to stop, per watch, per cycle -- which is how a 410 becomes an IP ban. The portal
  is not going to change its mind within the hour; the health state and a Telegram
  message are what should move, not the retry counter.

  **A 200 is not a success.** Challenge detection reads the body as well as the
  status, because a WAF is free to answer 200 and `CRAWL-DIAGNOSIS.md` records
  Berlin's WFS doing exactly that with a maintenance page.

  ## The seam

  `Portals` hands this module a plain `{slug, min_seconds_between_requests}` list at
  boot, through `pace/1`, and `fetch/2` takes a slug. Nothing here aliases
  `Portals.Portal` at runtime: `Portals` is a persistence domain, this is where the
  processes live, and the dependency points one way only.

  ## Etiquette

  `CRAWL-DIAGNOSIS.md` §9 asks for a polite, well-identified plain-HTTP tier. The
  header set below is a current browser's rather than a bespoke one, because a 2017
  Chrome string -- what the Node crawler sent -- is what gets a request classified
  as a bot before anyone reads it. Politeness is carried by the gate: a bounded,
  jittered request rate per portal, and a challenge that stops us asking rather than
  being worked around.
  """

  alias FindMeAFlat.Fetching.CookieJar
  alias FindMeAFlat.Fetching.Page
  alias FindMeAFlat.Fetching.PortalGate

  require Logger

  @type reason ::
          :challenged | :gone | :not_found | :rate_limited | :timeout | :transport_error
  @type result :: {:ok, Page.t()} | {:error, reason()} | {:error, :gated, pos_integer()}
  @type disposition :: :cancel | :retry | {:snooze, pos_integer()}

  # A 429 that we retry in a minute is a 429 again. Fifteen minutes is long enough
  # for a portal's window to roll over and short enough to keep a search useful.
  @rate_limited_snooze_seconds 900

  # Lowercase, matched against a downcased head of the body. Every one of these was
  # observed on a live probe or is the vendor's own published marker:
  # AWS WAF (ImmoScout24), DataDome (Immonet -> Immowelt), Cloudflare, PerimeterX.
  #
  # Each one is a host or an asset path, not a product name. A bare "datadome" also
  # matches the *cookie* DataDome sets on a perfectly ordinary page, and would
  # classify every subsequent success as a challenge; "captcha-delivery" is the host
  # that only an interstitial loads.
  @challenge_markers [
    "awswaf",
    "captcha-delivery",
    "ich bin kein roboter",
    "just a moment",
    "cf-chl-",
    "/cdn-cgi/challenge-platform",
    "px-captcha",
    "_px_captcha"
  ]

  # A challenge page is small and says so at the top; 64 KB reaches well past the
  # </head> of every portal page here. Downcasing a whole 1.2 MB listing page on
  # every fetch would cost more than the check is worth.
  @marker_scan_bytes 65_536

  # Chrome 141 on macOS, the shape a real navigation request has. Kept together so
  # there is one place to age it, and asserted on in the tests so it cannot rot
  # silently the way the Node crawler's 2017 string did.
  @browser_headers [
    {"accept",
     "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"},
    {"accept-language", "de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7"},
    {"sec-ch-ua", ~s("Chromium";v="141", "Google Chrome";v="141", "Not?A_Brand";v="24")},
    {"sec-ch-ua-mobile", "?0"},
    {"sec-ch-ua-platform", ~s("macOS")},
    {"sec-fetch-dest", "document"},
    {"sec-fetch-mode", "navigate"},
    {"sec-fetch-site", "none"},
    {"sec-fetch-user", "?1"},
    {"upgrade-insecure-requests", "1"},
    {"user-agent",
     "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"}
  ]

  @doc """
  Tells `Fetching` how often each portal may be asked, starting a gate per slug.

  This is the whole seam between `Portals` and `Fetching`: a list of
  `{slug, min_seconds_between_requests}`, handed over once at boot. Idempotent, so
  re-reading the portal rows adjusts intervals without resetting anyone's pacing.
  """
  @spec pace([{String.t(), non_neg_integer()}]) :: :ok
  def pace(portals) when is_list(portals) do
    Enum.each(portals, fn {slug, min_seconds} -> PortalGate.pace(slug, min_seconds) end)
  end

  @doc """
  Fetches one URL for one portal, through that portal's gate.

  Returns `{:ok, %Page{}}`, one of the six error reasons, or `{:error, :gated, ms}`
  when the portal is not due yet. The gate answers immediately either way: a caller
  is never parked waiting for a portal to become due.
  """
  @spec fetch(String.t(), String.t()) :: result()
  def fetch(slug, url) when is_binary(slug) and is_binary(url) do
    case PortalGate.request(slug) do
      :ok -> request(slug, url)
      {:error, :gated, ms} -> {:error, :gated, ms}
    end
  end

  @doc """
  What a worker should do about a fetch result.

  `:cancel` means discard the job and let the portal's health state carry the news.
  `:retry` means the failure was ours or the wire's. `{:snooze, seconds}` means come
  back later without spending an attempt.
  """
  @spec disposition({:error, reason()} | {:error, :gated, non_neg_integer()}) :: disposition()
  def disposition({:error, :challenged}), do: :cancel
  def disposition({:error, :gone}), do: :cancel

  # For the same reason as :gone. A search URL is a stored configuration value, and
  # no number of retries edits a row.
  def disposition({:error, :not_found}), do: :cancel

  def disposition({:error, :rate_limited}), do: {:snooze, @rate_limited_snooze_seconds}
  def disposition({:error, :timeout}), do: :retry
  def disposition({:error, :transport_error}), do: :retry

  def disposition({:error, :gated, ms}) when is_integer(ms) and ms >= 0 do
    {:snooze, max(1, ceil(ms / 1000))}
  end

  defp request(slug, url) do
    url
    |> transport().get(headers: headers(slug))
    |> outcome(slug, url)
  end

  defp outcome({:ok, response}, slug, url) do
    CookieJar.absorb(slug, response.headers)
    classify(response, url)
  end

  defp outcome({:error, :timeout}, _slug, _url), do: {:error, :timeout}

  defp outcome({:error, reason}, slug, url) do
    Logger.warning("fetch failed for #{slug} at #{url}: #{inspect(reason)}")
    {:error, :transport_error}
  end

  # Markers first, and deliberately: the status is the least reliable thing about a
  # response from a portal behind bot management.
  defp classify(response, url) do
    case challenge?(response.body) do
      true -> {:error, :challenged}
      false -> classify_status(response.status, response, url)
    end
  end

  defp classify_status(404, _response, _url), do: {:error, :not_found}
  defp classify_status(410, _response, _url), do: {:error, :gone}
  defp classify_status(429, _response, _url), do: {:error, :rate_limited}

  # A 401 or a 403 on a public search page is a bot wall whether or not the body
  # carried a marker we know.
  defp classify_status(status, _response, _url) when status in [401, 403],
    do: {:error, :challenged}

  defp classify_status(status, response, url) when status in 200..299 do
    case truncated?(response.body) do
      true -> {:error, :transport_error}
      false -> {:ok, Page.new(url, response.final_url, status, response.body)}
    end
  end

  defp classify_status(_status, _response, _url), do: {:error, :transport_error}

  defp challenge?(body) do
    scanned = body |> head() |> String.downcase()

    :binary.match(scanned, @challenge_markers) != :nomatch
  end

  defp head(body) when byte_size(body) <= @marker_scan_bytes, do: body
  defp head(body), do: whole_codepoints(binary_part(body, 0, @marker_scan_bytes))

  # Cutting a UTF-8 body at a byte offset can land mid-codepoint, and German pages
  # are full of multi-byte ones. Back off until the prefix is valid: at most three
  # bytes, and it keeps `String.downcase/1` fed with something it can read.
  defp whole_codepoints(prefix) do
    case String.valid?(prefix) do
      true -> prefix
      false -> whole_codepoints(binary_part(prefix, 0, byte_size(prefix) - 1))
    end
  end

  # A response that stops mid-document parses to zero listings, which the health
  # state would read as "the portal broke". It did not; the response did. Every
  # portal in scope serves HTML, so a missing closing tag is the honest signal, and
  # the cost of a false positive is one retry.
  defp truncated?(body), do: not String.contains?(body, "</html>")

  defp headers(slug) do
    case CookieJar.cookie_header(slug) do
      nil -> @browser_headers
      cookie -> [{"cookie", cookie} | @browser_headers]
    end
  end

  defp transport do
    Application.get_env(:find_me_a_flat, :portal_transport, FindMeAFlat.Fetching.Transport.Req)
  end
end
