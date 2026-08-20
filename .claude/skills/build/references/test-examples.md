# Test Examples

**Worked pairs, not rules.** [testing.md](testing.md) owns the rules and wins every
conflict; this file shows what they look like in our stack. There is no
`docs/craft/testing.md` and no `TST-00n` ids yet. Shapes are illustrative — check real
signatures with `get_source_location` before copying one.

Project-specific reference; inherit authority and scope from the calling skill.

**No Elixir code exists yet.** Every example below is the shape to write once it does.

## The seam, not the internals

A **seam** is the public boundary where behaviour is observable without reaching inside.
A test at a seam survives any refactor behind it, which is the property that makes the
module deep and the test worth keeping.

```elixir
# BAD — bound to internals. Renaming the private step breaks a test no behaviour changed.
test "build_delivery_params/2 sets sent_at" do
  assert %{sent_at: %DateTime{}} = Listings.Delivery.build_delivery_params(delivery, :sent)
end

# GOOD — the claim through the interface a caller uses.
test "marking a delivery sent records when it was sent" do
  {:ok, sent} = Listings.mark_delivered(delivery, actor: subscriber)
  assert sent.state == :sent
  refute is_nil(sent.sent_at)
end
```

The tell: **the test breaks when you refactor but behaviour has not changed.** That test
was measuring structure.

## Expected values come from outside the code

Ask whether the test rejects a meaningful wrong outcome. A **tautological** test cannot,
because it recomputes the expected value the way the code does — so it agrees with the
implementation by construction, including when the implementation is wrong.

```elixir
# BAD — the assertion is the implementation, run twice.
test "price per square metre" do
  expected = Decimal.div(listing.price_cents, listing.size_sqm)
  assert Listings.price_per_sqm(listing) == expected
end

# GOOD — an independent literal. It can disagree with the code.
test "price per square metre" do
  # 1.450,00 € over 62 m²  →  23,39 €/m²
  assert Listings.price_per_sqm(listing) == Decimal.new("23.39")
end
```

Same failure wearing other clothes: a snapshot derived by hand the way the code derives
it, and a constant asserted equal to itself. Expected values come from the requirement,
a worked example, or a known-good literal.

## Observe through the interface, not around it

```elixir
# BAD — a side channel. Passes even when the read path is broken.
test "creating a search persists it" do
  Searches.create_search!(attrs, actor: subscriber)
  assert Repo.one(from s in Search, where: s.name == ^attrs.name)
end

# GOOD — the interface answers for itself, through real policies and loads.
test "a created search is readable by its owner" do
  created = Searches.create_search!(attrs, actor: subscriber)
  assert {:ok, found} = Searches.get_search(created.id, actor: subscriber)
  assert found.name == attrs.name
end

# BETTER STILL — the multi-tenancy claim, which is the one that matters here.
test "a search is not readable by another subscriber" do
  created = Searches.create_search!(attrs, actor: subscriber)
  assert {:error, %Ash.Error.Forbidden{}} =
           Searches.get_search(created.id, actor: other_subscriber)
end
```

Ash behaviour goes through the domain: real policies, validations, changes, loads and
database constraints. Do not re-test declarative machinery we never customised.

**The forbidden-read test is not optional.** One deployment serves every subscriber, and
policies are the only thing separating them. A policy regression is silent otherwise.

## Parse against a stored fixture, never a live portal

The load-bearing test in this project. Five portals broke silently for months because
nothing asserted this.

```elixir
# BAD — hits the network. Fails on a train, rate-limits the portal, and passes
# for the wrong reason when the portal serves a challenge page with HTTP 200.
test "parses kleinanzeigen listings" do
  {:ok, html} = Req.get!("https://www.kleinanzeigen.de/s-wohnung-mieten/berlin/c203l3331")
  assert length(Portals.parse(:kleinanzeigen, html.body)) > 0
end

# GOOD — a committed fixture, an exact contract, and fields that must not be nil.
test "parses kleinanzeigen listings" do
  html = File.read!("test/support/fixtures/portals/kleinanzeigen_2026_08_20.html")
  {:ok, listings} = Portals.parse(:kleinanzeigen, html)

  assert length(listings) >= 25
  assert Enum.all?(listings, &(&1.external_id && &1.title && &1.url))
end

# GOOD — the failure mode that actually happened, asserted directly.
test "a bot-challenge page is not mistaken for an empty result" do
  html = File.read!("test/support/fixtures/portals/immoscout_waf_challenge.html")
  assert {:error, :challenged} = Portals.parse(:immoscout, html)
end

# GOOD — one malformed card must not take the other 31 with it.
test "an unparseable card is skipped, not fatal" do
  html = File.read!("test/support/fixtures/portals/immosuchmaschine_bad_price.html")
  {:ok, listings} = Portals.parse(:immosuchmaschine, html)
  assert length(listings) >= 20
end
```

`{:error, :challenged}` distinct from `{:ok, []}` is the whole point. The Node
predecessor could not tell them apart, which is why ImmoScout24 stayed broken and
nobody noticed.

## Double the transport, never the adapter

Mock at owned external seams only. Our own modules are never doubled; doubling one
asserts our own code was called rather than that behaviour happened.

```elixir
# BAD — doubles the thing under test. Proves nothing about parsing or error mapping.
expect(PortalFetcherMock, :fetch_listings, fn _url -> {:ok, [%Listing{}]} end)

# GOOD — double the remote transport; run the real fetcher's translation.
expect(HttpTransportMock, :get, fn "https://www.kleinanzeigen.de/" <> _ ->
  {:ok, %{status: 200, body: File.read!("test/support/fixtures/portals/kleinanzeigen.html")}}
end)

assert {:ok, listings} = Fetching.fetch_and_parse(portal, url)
assert hd(listings).price_cents == 145_000
```

The double supplies what the remote service would send, **including failures a live
service cannot produce on demand** — a 410 Gone, a WAF challenge body under HTTP 200, a
truncated response, a timeout. Those are this project's real failure modes and a live
portal will not perform them for you.

Time and randomness are boundaries too. Everything else — our own collaborators,
internal modules, anything we control — is not.

## Two seams, two opposite rules

Doubling goes wrong when the adapter's seam and the transport's seam get treated as one.
They carry opposite rules.

| Seam | Who calls it | Shape | Double allowed |
| --- | --- | --- | --- |
| Domain → fetcher | our own code | one named operation per remote capability | no — this is the code under test |
| Fetcher → transport | the fetcher | generic `get`/`post` over a URL | yes, and nowhere else |

**Name one operation per remote capability at the upper seam.** A domain calling
`HTTPClient.get(url, opts)` learns the portal's URLs, headers, and cookie conventions.
A fetcher exposing `fetch(url, opts)` hides all three. It also keeps the double a
literal: a generic transport forces every double to branch on the URL to decide what to
return.

```elixir
# BAD — the domain knows the transport. Every caller repeats URL, headers, and shape.
def newest_listings(portal) do
  {:ok, resp} = HTTPClient.get(portal.base_url <> "/suche", headers: portal_headers())
  Floki.find(resp.body, portal.container)
end

# GOOD — one named operation. The fetcher owns URL, headers, cookies and translation.
def newest_listings(portal) do
  with {:ok, page} <- Fetching.fetch(portal, search_url(portal)), do: Portals.parse(portal, page)
end
```

**Accept the transport; never construct it.** A fetcher reaching for its own client
leaves the test nothing to replace.

```elixir
# BAD — the fetcher picks its collaborator, so no test can vary it.
def fetch(portal, url), do: Req.get(url, headers: portal.headers)

# GOOD — the transport arrives, so production and test each supply one.
def fetch(portal, url, transport \\ transport()) do
  url |> transport.get(headers: portal.headers) |> translate()
end

defp transport, do: Application.get_env(:find_me_a_flat, :portal_transport, FindMeAFlat.Fetching.HttpFetcher)
```

**Two implementations, or no seam.** A fetcher seam whose second implementation stays
hypothetical is indirection. Here it is genuine: `HttpFetcher` (Req + Finch) and
`BrowserFetcher` (headless Chrome, for ImmoScout24) are both real, plus the test double.
