# Target Architecture — Elixir / Phoenix / Ash

The design that turns *one deployment per person* into *one deployment for everyone*,
and turns silent crawl failures into loud ones.

---

## 1. The two problems, restated precisely

**Problem A — one instance per person.** The chat ID lives in `conf/config.json`, read
at import time, and the seen-listing set is a global array in one JSON file. Both are
process-global singletons. Serving a second person requires a second process, a second
config file and a second volume. Five people, five deployments.

**Problem B — setup requires a terminal.** Before first run a user must create a bot
with BotFather, message it, run `curl .../getUpdates`, read a JSON blob, extract a
numeric chat ID, paste it into a JSON file, assemble portal search URLs by hand, and
mount the file into a container. Every step is a place to fail, and none of it can be
done from a phone.

Both dissolve for the same reason: **Telegram already tells you who is talking.** Every
incoming update carries `message.chat.id`. A bot that *receives* messages never needs
a chat ID configured — it learns one per user, on `/start`, for free. The current
Telegram library (`tg-yarl`, last published 2016) is send-only, which is the mechanical
reason this was never possible.

---

## 2. System shape

**Surfaces are decided, and the split is unusually clean:**

| Audience | Surface | Auth |
|---|---|---|
| **Users** | **Telegram only.** No user-facing web UI, ever | Telegram identity — `chat.id` |
| **Admin (Chris)** | **Phoenix/LiveView only**, plus `ash_admin` | **AshAuthentication** |
| **Machines** (near future) | **MCP server** via `ash_ai` | AshAuthentication API keys or OAuth 2.1 |

This simplifies the security model considerably. The **only** unauthenticated public
route in the entire application is the Telegram webhook, protected by a secret path
segment and the `X-Telegram-Bot-Api-Secret-Token` header. Everything else sits behind
authentication. There is no user registration, no password reset, no magic-link flow for
subscribers, no session management for the public — because the public never touches the
web app at all.

```
                        ┌──────────────────────────────────────┐
   Telegram  ──webhook──▶│  FindMeAFlatWeb  (Phoenix endpoint)  │
                        │   • ExGram webhook plug  ← only       │
                        │     public route                      │
                        │   • /admin  LiveView + ash_admin      │
                        │       └ AshAuthentication              │
                        │   • /mcp    AshAi.Mcp.Router          │
                        │       └ API key / OAuth 2.1           │
                        └───────────────┬──────────────────────┘
                                        │
                        ┌───────────────▼──────────────────────┐
                        │  FindMeAFlat.Bot   (ExGram)          │
                        │   /start /new /list /pause /delete    │
                        │   conversational search wizard        │
                        └───────────────┬──────────────────────┘
                                        │
   ┌────────────────────────────────────▼──────────────────────────────────┐
   │                         Ash domains                                    │
   │  Accounts    Subscriber                                                │
   │  Searches    Search · SearchPortal · Filter                            │
   │  Listings    Listing · Delivery                                        │
   │  Portals     Portal · SelectorSet · PortalHealth                       │
   └────────────────────────────────────┬──────────────────────────────────┘
                                        │  AshOban triggers + scheduled actions
   ┌────────────────────────────────────▼──────────────────────────────────┐
   │  Oban queues                                                           │
   │   :crawl        one job per (Search × Portal) due                      │
   │   :parse        HTML → candidate listings                              │
   │   :deliver      one job per (Subscriber × Listing), rate-limited       │
   │   :maintenance  health checks, fixture drift, pruning                  │
   └────────────────────────────────────┬──────────────────────────────────┘
                                        │
   ┌────────────────────────────────────▼──────────────────────────────────┐
   │  FindMeAFlat.Fetching                                                  │
   │   Fetcher behaviour ── HttpFetcher   (Req + Finch, cookie jar)         │
   │                    └── BrowserFetcher (headless Chrome, deferred)      │
   │   PortalGate GenServer per portal — token-bucket pacing                │
   └────────────────────────────────────────────────────────────────────────┘
                                        │
                                   PostgreSQL
```

Single OTP release. Single database. Any number of users.

---

## 3. Domain model

Four Ash domains. Names are domain language, not technical labels.

### `FindMeAFlat.Accounts`

**`Subscriber`** — a person who receives notifications.

| Attribute | Type | Notes |
|---|---|---|
| `id` | uuid v7 | |
| `telegram_chat_id` | integer | **unique**; identity for upsert on `/start` |
| `telegram_username` | string | display only, may be nil |
| `chat_type` | atom | `:private \| :group \| :supergroup` — groups work identically |
| `locale` | atom | `:de \| :en`, defaults from Telegram's `language_code` |
| `state` | atom | `:active \| :paused \| :blocked` |
| `quiet_hours_from/to` | time | nil = always deliver |
| `timezone` | string | for quiet hours |

The `blocked` state matters: when Telegram answers `403 Forbidden: bot was blocked by
the user`, the subscriber is marked blocked and all their searches stop being crawled.
The current system has no way to notice this and would crawl forever for a departed user.

**`Subscriber` is created by upsert on `telegram_chat_id`.** That single line is the
whole of Problem A's fix.

### `FindMeAFlat.Searches`

**`Search`** — one saved hunt belonging to one subscriber.

| Attribute | Type | Notes |
|---|---|---|
| `subscriber_id` | belongs_to | |
| `name` | string | user-chosen, e.g. "Wedding 2 Zimmer" |
| `city` | string | |
| `min_size` / `max_rent` / `min_rooms` | integer | nil = unbounded |
| `wanted_districts` | `{:array, :string}` | |
| `blacklist_terms` | `{:array, :string}` | |
| `interval_minutes` | integer | default 5, floor enforced per portal |
| `state` | atom | `:active \| :paused` |
| `last_crawled_at` | utc_datetime_usec | |

**`SearchPortal`** — join between a `Search` and a `Portal`, carrying the portal-specific
search URL and per-pair state.

| Attribute | Notes |
|---|---|
| `search_id`, `portal_id` | unique together |
| `search_url` | the pasted portal URL, or nil when the portal builds its own |
| `builder_params` | map — for wg-gesucht style URL construction |
| `state` | `:active \| :paused \| :broken` |
| `consecutive_empty_runs` | integer — the health signal |
| `last_success_at`, `last_error` | |

~~`consecutive_empty_runs` is the mechanism that would have caught every failure in
`CRAWL-DIAGNOSIS.md`.~~ **Wrong, and refuted by this proposal's own evidence.** The
signal as specified fires only on *zero cards from a 200*, but `CRAWL-DIAGNOSIS.md`'s
status column shows 403, 401, 410 and 410 for four of six portals — they never return
200, so the counter never increments — and immosuchmaschine returns 200 with 22 cards
whose IDs collapse, which is not zero. It would have caught **one** of six: wg-gesucht.
See `PLAN.md` S12, which drives health from terminal fetch outcomes and per-field fill
rates instead. Three consecutive zero-parseable-card runs on a portal that
previously produced listings flips `state` to `:broken` and messages the subscriber:
*"Immowelt hasn't returned any listings for 15 minutes — the portal may have changed.
I've paused it."* Silence becomes a message.

### `FindMeAFlat.Listings`

**`Listing`** — a flat, **shared across all subscribers**.

| Attribute | Notes |
|---|---|
| `portal_id` + `external_id` | **unique together** — the global dedupe key |
| `title`, `district`, `price_cents`, `size_sqm`, `rooms`, `url` | |
| `address_street`, `address_house_number`, `address_postcode`, `address_city` | **structured, not free text** |
| `latitude`, `longitude` | geocoded at parse time |
| `building_id` | nullable FK into `Reference.Building`, filled from Phase 2 |
| `provider_name`, `provider_kind` | `:company \| :individual \| :unknown` — the Anbieter as listed |
| `description` | **full text, never truncated** |
| `image_urls` | `{:array, :string}` — **must be captured in Phase 1** |
| `raw` | map — everything the parser extracted, kept forever |
| `first_seen_at`, `last_seen_at` | |

**`description` and `image_urls` are the two fields that cannot be recovered later.**
A delisted scam listing takes its photos and its text with it, and `CREDIBILITY.md` §4
depends on both — photo reuse across portals is the strongest scam signal the crawler
can compute, and it needs the image URLs captured at crawl time. Everything else in the
enrichment roadmap can be derived from stored data whenever it is built; these two must
be captured now or never.

**Listings are stored in full and never pruned.** `db/listing.json` keeps bare IDs and
throws the listing away; that is the single most expensive thing about the current
design, because the accumulated dataset is what `PRODUCT-VISION.md` is built on. A
year of stored listings is a few hundred thousand rows — trivial for Postgres, and
impossible to recreate after the fact.

Structured address and coordinates are captured at parse time for the same reason:
retro-geocoding a year of free-text addresses is painful, capturing them now is free.

This is the second structural win. **One crawl of Immowelt serves every subscriber
searching Berlin.** Today five people means five crawls of the same page — five times
the request volume, five times the bot-detection exposure, five times the chance of
being blocked. Deduplicating the *fetch* is both cheaper and safer.

**`Delivery`** — the per-person seen-set, replacing `db/listing.json`.

| Attribute | Notes |
|---|---|
| `subscriber_id` + `listing_id` | **unique together** |
| `search_id` | which search matched |
| `state` | `:pending \| :sent \| :failed \| :suppressed` |
| `attempts`, `last_error`, `sent_at` | |

A failed delivery stays `:failed` with an attempt count and is retried by Oban. It is
never silently marked seen. That is the fix for the "transient Telegram outage loses
listings forever" behaviour.

### `FindMeAFlat.Portals`

**`Portal`** — `immowelt`, `kleinanzeigen`, `immosuchmaschine`, `wg_gesucht`,
`immoscout`. Carries `slug`, `base_url`, `fetcher` (`:http | :browser`),
`min_seconds_between_requests`, `state`.

**`SelectorSet`** — versioned extraction rules as *data*.

```elixir
%SelectorSet{
  portal_id: kleinanzeigen.id,
  version: 3,
  active: true,
  container: "#srchrslt-adtable .ad-listitem",
  fields: %{
    "external_id"  => %{"selector" => ".aditem", "attr" => "data-adid", "cast" => "integer"},
    "title"        => %{"selector" => ".aditem-main .text-module-begin a", "cast" => "text"},
    "url"          => %{"selector" => ".aditem-main .text-module-begin a", "attr" => "href"},
    "price"        => %{"selector" => ".aditem-main--middle--price", "cast" => "money"},
    "description"  => %{"selector" => ".aditem-main--middle--description"},
    "address"      => %{"selector" => ".aditem-main--top--left"}
  },
  pagination: %{"selector" => "#srchrslt-pagination .pagination-next", "attr" => "href"}
}
```

Why data and not code: portals change their markup a few times a year, and the current
design requires editing JavaScript, rebuilding a Docker image and redeploying to change
one CSS string. As rows, a broken portal is repaired by an admin write — or by the
maintainer from a phone — with no deploy. Versioning means a bad selector edit is
reverted by flipping `active`.

The bespoke bits that genuinely *are* code — Immowelt's `classified-card-mfe-<id>` split,
wg-gesucht's 22-parameter URL builder, immosuchmaschine's URL-inside-JavaScript
extraction — stay in the portal's Elixir module, behind the `Portal` behaviour. Data
covers the boring 90%; code covers the rest.

**`PortalHealth`** — a rolling record per portal: last success, cards parsed, HTTP
status distribution, challenge-detected count. Feeds `/status` in the bot and an admin
LiveView.

### `FindMeAFlat.Reference` — reserved in Phase 1, populated later

Empty at first, but declared now so enrichment never sprawls into `Listings`. See
`PRODUCT-VISION.md` for sequencing and `OPEN-DATA.md` for what each source actually
provides.

| Resource | Holds | Source |
|---|---|---|
| `Wohnlage` | address → `:einfach \| :mittel \| :gut` | Berlin WFS, dl-de/zero-2.0 — **current edition only, no historic series** |
| `Building` | address, coordinates, age class, storeys, Denkmalschutz | Umweltatlas (block level) + OSM |
| `MietspiegelTable` | city, validity period, source, digitisation provenance | Dortmund API; hand-digitised elsewhere |
| `MietspiegelEntry` | (Gebiet × Wohnflächenklasse × Baualtersklasse × Ausstattung) → €/m² | as above |
| `Provider` | Hausverwaltung / agency, contact data, listing history | listing Anbieter + public Impressum |
| `CredibilityAssessment` | score, band, explainable flags per listing | derived — see `CREDIBILITY.md` |

Berlin publishes Wohnlagen back to 2003, which would give per-address rent trajectories.
**Skipped by decision** — only the current edition is ingested. The historic series is a
research capability, not a product one, and it multiplies ingestion volume for something
no user asked for.

**`Provider` stores commercial entities only.** A company's Impressum is legally public
data; a private individual landlord's details are personal data whose indirect
collection triggers GDPR Art. 14 notification duties that cannot be met at scale. The
`provider_kind` classification on `Listing` is the gate.

### `Filter` as a resource, not columns

`Search` carries the obvious scalars, but filters live as their own rows:

```elixir
%Filter{search_id: …, kind: :max_rent,                  value: %{"cents" => 120_000}}
%Filter{search_id: …, kind: :blacklist_term,            value: %{"term" => "tausch"}}
%Filter{search_id: …, kind: :district_allowlist,        value: %{"districts" => ["Wedding"]}}
%Filter{search_id: …, kind: :percent_over_reference,    value: %{"max_percent" => 15}}   # Phase 3
```

The last kind is the reason. `max_percent_over_reference` is not a column comparison —
it needs the Mietspiegel join — and modelling filters as rows now avoids a migration
across every user's searches when it arrives. It is also, per `PRODUCT-VISION.md` §2.1,
the *better* filter: relative to the neighbourhood reference rather than an absolute
ceiling.

---

## 4. Onboarding — Problem B's fix

Everything happens inside Telegram. No file, no terminal, no `getUpdates`.

```
User: /start
Bot:  Hi! I watch German flat portals and message you when something new appears.
      Let's set up your first search — takes about a minute.
      Which city?                                      [Berlin] [Hamburg] [München] [other…]

User: [Berlin]
Bot:  Max rent per month?                              [800] [1200] [1600] [no limit]
User: 1200
Bot:  Minimum size?                                    [40 m²] [60 m²] [80 m²] [no minimum]
User: 60
Bot:  Any districts in particular? Send them comma-separated, or /skip.
User: Wedding, Friedrichshain
Bot:  Which portals?  (tap to toggle, then Done)
      ☑ Immowelt   ☑ Kleinanzeigen   ☑ WG-Gesucht   ☑ Immosuchmaschine
      ⚠ ImmoScout24 — currently blocking automated access
Bot:  Done — "Berlin ≤1200 € ≥60 m²" is live, checking every 5 minutes.
      /list to see your searches · /pause to stop · /settings for more
```

`chat_id` is taken from the incoming update. The subscriber row is upserted. The search
and its `SearchPortal` rows are built from the answers, and **the portal search URLs are
generated by the portal modules from the structured parameters** — the user never sees
a URL.

The pasted-URL path stays available for power users (`/addurl <url>`): the bot detects
the portal from the host, validates it, and attaches it to a search. That preserves the
current tool's best idea without making it the only door.

Group chats work with no extra code, because a group's `chat.id` is just another chat
id — which is what the user's flatmates or partner actually want.

**There is deliberately no user-facing web UI.** Everything a subscriber can do happens
in Telegram: `/new`, `/list`, `/pause`, `/delete`, `/settings`, `/status`. This is a
decision, not a deferral — it removes user authentication, session handling, password
flows and a whole public attack surface from the product permanently, and it keeps the
onboarding promise ("set it up from your phone, no terminal") literally true.

Phoenix is in the stack for the **admin** surface and the **MCP** surface, not for users.

---

## 5. Crawl pipeline

### Scheduling

An AshOban **scheduled action** runs every minute and enqueues one `:crawl` job per
`SearchPortal` whose `last_crawled_at` is older than its interval. Jobs are `unique`
on `{search_portal_id}` with a short period, so a slow portal cannot pile up — which
replaces the crude global `isRunning` flag that currently causes *every* source to skip
a tick when *one* source hangs.

### Fetching

```elixir
defmodule FindMeAFlat.Fetching.Fetcher do
  @callback fetch(url :: String.t(), opts :: keyword()) ::
              {:ok, %{status: pos_integer(), body: String.t(), final_url: String.t()}}
              | {:error, :challenged | :not_found | :gone | :timeout | term()}
end
```

Two implementations. `HttpFetcher` uses `Req` over a named `Finch` pool with HTTP/2, a
per-portal cookie jar, a full realistic header set (`Accept`, `Accept-Language: de-DE`,
`Sec-Fetch-*`, a *current* Chrome UA rather than the 2017 one in the example config),
redirect following, and decompression. `BrowserFetcher` is a deferred bet.

**Challenge detection is a first-class result, not an exception.** `{:error, :challenged}`
is returned when the body matches known markers (`awswaf`, `captcha-delivery`,
`Ich bin kein Roboter`, `Just a moment`). The current system cannot distinguish a bot
wall from an empty search — that is exactly how ImmoScout24 stayed silently broken.

**`PortalGate`** — one `GenServer` per portal enforcing a token bucket
(`min_seconds_between_requests` with jitter). Every fetch passes through it, so no
matter how many searches or subscribers exist, a portal sees a bounded, polite request
rate. Note that Oban OSS has per-queue concurrency but **not** per-key rate limiting
(that is Oban Pro), which is why the gate is its own process rather than queue config.

### Parsing

`Floki.parse_document/1`, then the `SelectorSet` applied field by field. Every listing
is parsed independently:

```elixir
listings =
  document
  |> Floki.find(selector_set.container)
  |> Enum.map(&parse_card(&1, selector_set, portal))
  |> Enum.split_with(&match?({:ok, _}, &1))
```

A card that fails to parse produces `{:error, reason}` and is counted — **it does not
take the other 31 with it**. That is the direct fix for `immosuchmaschine`'s
`price.split('€ ')[1]` rejecting an entire cycle.

If **zero** cards parse from a 200 response, that is the health signal: increment
`consecutive_empty_runs`, and at the threshold flip to `:broken` and notify.

### Matching and delivery

Parsed listings are upserted on `{portal_id, external_id}`. Each new listing is matched
against every active `Search` that includes this portal — filters evaluated in the
database, not in Elixir, so it scales past a handful of users. Matches create `Delivery`
rows, deduped by the `{subscriber_id, listing_id}` unique index.

The `:deliver` queue sends them. **Telegram's limits are ~30 messages/second globally
and ~20 messages/minute to a single group**, so delivery is paced per subscriber, with
`429` handled by reading `retry_after` and snoozing the Oban job — a real backoff
rather than the current single retry.

**Message formatting uses `parse_mode: "HTML"`, not Markdown.** HTML needs only `&`,
`<`, `>` escaped, which is mechanical and total. Legacy Markdown requires balancing
`_ * [ ]` inside arbitrary German listing titles, which is why titles containing an
underscore currently produce a 400 and vanish.

---

## 6. Supervision tree

```
FindMeAFlat.Supervisor
├── FindMeAFlat.Repo
├── {Phoenix.PubSub, name: FindMeAFlat.PubSub}
├── {Finch, name: FindMeAFlat.Finch, pools: %{...}}
├── FindMeAFlat.Portals.GateSupervisor      (one PortalGate per portal)
├── {Oban, ...}
├── FindMeAFlatWeb.Endpoint
└── FindMeAFlat.Bot                          (ExGram; webhook in prod, polling in dev)
```

### Admin surface

`/admin` behind **AshAuthentication**, single operator account, no registration route.
`ash_admin` provides CRUD over every resource for free — which is exactly the
selector-repair console `SelectorSet`-as-data was designed for. Alongside it, a small
number of purpose-built LiveViews: portal health, crawl throughput, delivery failures,
Mietspiegel ingestion status.

**`ash_admin` must be mounted inside the authenticated scope, never beside it.** It
exposes destructive actions on every resource by default; an unauthenticated
`/admin` route is a full database console on the public internet.

### MCP surface

`ash_ai` ships a production MCP server (`AshAi.Mcp.Router`, protocol `2025-03-26`) that
turns Ash actions into MCP tools. Authentication is **API keys**
(`AshAuthentication.Strategy.ApiKey.Plug`) for statically-configured clients, or OAuth 2.1
via `ash_authentication_oauth2_server` for remote ones — so AshAuthentication is load-
bearing for this surface too, not only for admin.

Natural tools to expose: search listings by area, price and Mietspiegel deviation; look
up the reference rent for an address; look up a Hausverwaltung and its listing history;
fetch a listing's credibility assessment. That is a genuinely useful research interface
over the accumulated dataset, and it is close to free once the domain actions exist.

Two constraints from `ash_ai`'s design worth knowing before modelling resources:

- **Only `public?: true` attributes can be used for filtering and sorting** by tools;
  private attributes need an explicit `load`. Attribute visibility becomes an API design
  decision, not just an internal one.
- Vectorisation requires **pgvector** via AshPostgres, with update strategies
  `:after_action`, `:ash_oban`, or `:manual`. If semantic search over listing
  descriptions is ever wanted, `:ash_oban` is the right strategy here — embedding
  generation must not sit in the crawl path.

**Enable `postgis` and `vector` in the very first migration**, even though nothing uses
them in Phase 1. Adding extensions to a live database later is a migration nobody
enjoys, and both are on the roadmap.

Deliberately boring. Oban owns scheduling and retries, so there is no per-search
`GenServer` and no `DynamicSupervisor` for searches — state lives in Postgres where it
survives a deploy. The only long-lived custom processes are the per-portal gates, which
hold genuinely ephemeral state (a token bucket).

---

## 7. Where Elixir actually earns its keep

Worth being honest, because "rewrite it in Elixir" is not by itself a reason.

| Property | Node today | Elixir target |
|---|---|---|
| One slow portal blocks all others | yes (`isRunning` skips the whole tick) | no — independent Oban jobs |
| One bad listing kills a source cycle | yes (unguarded `map`) | no — per-card `{:ok, _} \| {:error, _}` |
| Failed notification loses the listing | yes | no — `Delivery` retried with backoff |
| Serving N users | N deployments | one, N rows |
| Crawl volume for N users | N × pages | 1 × pages |
| Changing a selector | edit JS, rebuild image, redeploy | update a row |
| Portal silently broken | indistinguishable from "no new flats" | `:broken` state + a Telegram message |
| Scheduling | `setInterval` in one process | durable jobs surviving restarts |
| Web UI for the "other ideas" | would be a second app | LiveView in the same app |

Elixir is not faster at parsing HTML than Node. What it brings here is **supervised
isolation of many independent, failure-prone jobs**, and a first-class path to a web UI
for the ideas that come after this one. If those two things were not on the table, the
honest recommendation would be to fix the six selectors in place.

---

## 8. Deliberately out of scope for the first bet

- **The ImmoScout24 browser tier.** Configured, visibly degraded, decided separately.
- **Immowelt pagination.** Page 1 only, ~32 newest cards per run. Revisit if listings
  are demonstrably missed.
- **Immonet.** Deleted; the portal no longer exists.
- **`maxDistanceInKilometres`.** Its only consumer was Immonet. Re-home as a general
  radius filter or drop.
- **Full web UI.** Ship the Telegram wizard first; the LiveView surface comes with the
  next set of ideas.
- **Public multi-tenant hosting.** The design supports it, but running a service for
  strangers brings GDPR, abuse and cost questions this proposal does not answer.
  Target is "one deployment that serves you, your sister and a few friends."
- **Every enrichment capability** — Mietspiegel comparison, building data, provider
  directory, contact strategy. These are Phases 2–5 in `PRODUCT-VISION.md`, each its own
  bet. Phase 1 owes them exactly five things, all cheap and all listed in
  `PRODUCT-VISION.md` §4: full listing storage, structured addresses with coordinates,
  the reserved `Reference` domain, `Filter` as a resource, and locale captured on first
  contact. Nothing else about the enrichment work belongs in this bet.
