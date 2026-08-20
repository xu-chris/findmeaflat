# Stack and Bootstrap Plan

Every version below was read from the hex.pm API on **2026-08-20**. Where the newest
release is a pre-release, both are shown, because pinning an RC in a hobby project that
must run unattended for months is usually the wrong trade.

---

## 1. Decided — the spine

| Package | Latest | Pin | Why |
|---|---|---|---|
| `phoenix` | 1.8.11 | `~> 1.8` | Telegram webhook + admin surface + MCP router |
| `phoenix_live_view` | 1.2.10 | `~> 1.2` | **Admin only** — users never see the web app |
| `ash` | 3.32.0 | `~> 3.0` | Declarative resources, policies, code interfaces |
| `ash_postgres` | 2.12.0 | `~> 2.0` | Data layer + generated migrations |
| `ash_phoenix` | 2.3.24 | `~> 2.0` | `AshPhoenix.Form` for the LiveView surface |
| `ash_oban` | 0.8.13 | `~> 0.8` | Triggers and scheduled actions on resources |
| `oban` | 2.23.1 | `~> 2.23` | Durable scheduling, retries, backoff |
| `igniter` | 0.8.3 | `~> 0.8` | Composable generators; every install below runs through it |

**Ash rather than plain Ecto contexts.** The pull is not the resource DSL — it is that
this app is mostly *policy plus background jobs*: "this subscriber may only see their
own searches", "this action runs every N minutes", "this state transition notifies".
Ash policies and AshOban triggers express that declaratively, and `ash_admin` gives a
selector-repair console for free. The cost is real: a large DSL to learn, and generated
migrations that must be read before they are run. Worth it here because the *next*
ideas are web-facing; not worth it for a bot that only ever posts to Telegram.

---

## 2. Decided — Telegram

| Package | Latest | Verdict |
|---|---|---|
| **`ex_gram` 0.69.0** | updated **2026-08-04** | **Chosen** |
| `nadia` 1.6.1 | updated 2026-06-26 | Rejected — thin API wrapper, no update loop or dispatcher |
| `telegex` 1.9.0-rc.0 | stable **1.8.0**, RC since **2024-09-18** | Rejected — stalled on an RC for two years |
| `telegram` 0.0.3 | 2016 | Rejected — abandoned |

`ex_gram` is actively maintained, and it is the only option that supplies what this
rewrite hinges on: a **receiving** bot. It provides both `ExGram.Updates.Poller` (dev)
and a webhook plug (prod), a dispatcher with `handle({:command, :new, msg}, context)`
clauses, per-update context, middleware, and inline keyboards for the setup wizard.

The replacement for `tg-yarl` is not "a newer send function" — it is the update loop.
Without it, `chat_id` can never be learned at runtime, and Problem A cannot be solved
in any language.

---

## 3. Decided — fetching and parsing

| Package | Latest | Pin | Role |
|---|---|---|---|
| `req` | 0.8.0-rc.0 / stable **0.7.3** | `~> 0.7` | HTTP client. **Pin the stable line, not the RC** |
| `finch` | 0.23.0 | (via Req) | Named pools, HTTP/2, per-portal connection reuse |
| `floki` | 0.38.4 | `~> 0.38` | HTML parsing + CSS selectors |

`Req` gives redirect following, decompression, retry hooks and a pluggable step
pipeline, over Finch pools that can be sized per portal. Cookie handling is a small
custom step — worth writing, because a persistent jar across a redirect chain is one of
the things the current stack cannot do at all.

**Rejected: `crawly`** (0.17.2, last updated **2024-07-04**). A full crawler framework
with its own scheduler and pipelines, aimed at broad site crawls. This app crawls six
known URLs on a fixed cadence; Oban already owns scheduling. Adopting Crawly would mean
two schedulers and a semi-maintained dependency in the hot path.

**Rejected: `meeseeks`** (0.18.0) and `html5ever`. Meeseeks offers XPath and stricter
html5ever parsing, which is genuinely better for malformed markup. Floki wins on
ecosystem familiarity and can use html5ever as its own backend if a portal's HTML turns
out to need it — that is a later, local swap.

**Deferred: the browser tier.** For ImmoScout24 only, and it is the weakest part of the
Elixir story — there is no mature production headless-browser client in the ecosystem:

- `wallaby` 0.31.0 — actively maintained, but it is a *test* tool (feature tests via
  WebDriver). Usable, off-label.
- `playwright` — newest is `1.49.1-alpha.2`, latest stable is `0.1.17-preview-7`. Alpha.
- `chrome_remote_interface` 0.4.1 — last published **2019**.
- `chromic_pdf` 1.17.1 — well maintained and actually drives Chrome over CDP, but its
  API is shaped for PDF/PNG output rather than DOM extraction.

If the browser tier is bet on, the most honest option is probably a **small sidecar
service** (Playwright or Puppeteer in its own container) that Elixir calls over HTTP,
rather than forcing a browser protocol client into Elixir. Worth naming plainly: this
is one area where Node has the better libraries, and a rewrite loses ground.

---

## 3a. Decided — admin auth and the MCP surface

| Package | Latest | Stable | Pin | Role |
|---|---|---|---|---|
| `ash_authentication` | 5.0.0-rc.12 | **4.14.1** | `~> 4.14` | Admin login; API keys for MCP |
| `ash_authentication_phoenix` | 3.0.0-rc.9 | **2.17.2** | `~> 2.17` | Admin LiveView auth routes |
| `ash_admin` | 1.3.0 | 1.3.0 | `~> 1.3` | CRUD console — the `SelectorSet` repair UI |
| `ash_ai` | 0.8.2 | 0.8.2 | `~> 0.8` | MCP server, prompt-backed actions, vectorisation |

**Pin the stable 4.x/2.x lines, not the v5 RCs.** A hobby-scale admin login has no need
for anything in v5, and an RC that must run unattended for months is the wrong trade.
The v5 upgrade is a deliberate later move.

**AshAuthentication is load-bearing in two places**, which is why it graduated from
candidate to decided: the admin surface, and `ash_ai`'s MCP server, whose authentication
options are `AshAuthentication.Strategy.ApiKey.Plug` (static clients) or
`ash_authentication_oauth2_server` (remote clients). There is no third option, so the
MCP roadmap item requires it regardless.

**`ash_ai` 0.8.2** (2026-08-03) provides, verified from its docs:

- **MCP server, two variants.** `AshAi.Mcp.Dev` mounted in the `code_reloading?` block
  for editor integration; `AshAi.Mcp.Router` for production, protocol `2025-03-26`.
  `mix ash_ai.gen.mcp` installs both.
- **Tools from Ash actions**, declared in domain/resource DSL blocks. Constraint worth
  knowing early: **only `public?: true` attributes can be filtered or sorted on** by
  tools; private ones need an explicit `load`. Attribute visibility becomes an API
  design decision.
- **Prompt-backed actions** — generic actions whose implementation is an LLM call with
  structured output.
- **Vectorisation** requiring **pgvector** via AshPostgres, with `:after_action`,
  `:ash_oban` or `:manual` update strategies. If semantic search over descriptions is
  ever wanted, `:ash_oban` is the only sane choice — embedding generation must never sit
  in the crawl path.

Not installed in Phase 1. Listed here because it dictates two Phase 1 decisions:
**enable the `vector` and `postgis` extensions in the first migration**, and treat
attribute visibility as deliberate.

---

## 4. Candidates — worth a decision, not yet decided

| Package | Latest | For | Against |
|---|---|---|---|
| `ash_paper_trail` 0.6.0 | | Audit log per resource. `SelectorSet` edits and Mietspiegel ingestion both want provenance | Adds a version table per tracked resource |
| `ash_state_machine` 0.2.13 | | `Delivery` and `SearchPortal` both have real state machines | Small enough to model with plain atom attributes + validations |
| `ash_money` 1.x | | Prices as `Money`, not naked integers | `price_cents` + a formatter covers it |
| `error_tracker` / `sentry` | | The current app's failures were invisible for months — this is the theme of the whole proposal | One more service to run |
| `oban_web` | | Live queue dashboard; crawl failures become visible | Licensing — check current terms before assuming free |
| `req_llm` / `instructor` | | Parse listings with an LLM when selectors break, as a fallback tier. `ash_ai` brings ReqLLM anyway | Cost, latency, non-determinism. Interesting, not first-bet |
| `bandit` | | Default Phoenix 1.8 adapter already | No decision needed |
| `usage_rules` | | Repo harness already expects `mix usage_rules.sync` for `dependencies.md` | Dev-only |

**Dev/test tooling has its own document.** `QUALITY-GATES.md` covers the full set —
`sobelow`, `mix_audit`, `excellent_migrations`, `quokka`, `credo` plus four check
plugins, `ex_dna`, `doctor`, `excoveralls`, `mix_test_watch`, `tidewave` — with verified
versions, four recommended changes (drop `exploit_guard`, Quokka *instead of* Styler,
skip `git_hooks`, fix two version pins), and a staged adoption order. It is a separate
document because ~126 third-party lint checks across five plugins need sequencing, not a
dependency list.

One item from it belongs here, because it interacts with this section's generator
sequence: **`excellent_migrations`**. Step 4 below runs `mix ash.codegen`, which produces
migrations nobody wrote by hand. `mix excellent_migrations.check_safety` turns "read the
generated SQL before running it" from an instruction into a CI gate.

---

## 4a. Phase 2+ — enrichment stack (not installed in Phase 1)

Needed only once the Mietspiegel and building work starts. Listed here so Phase 1's
schema choices do not paint them into a corner.

| Package | Stable | Role |
|---|---|---|
| `geo` | 4.1.0 | Geometry structs, **GeoJSON encode/decode** — reads WFS output directly |
| `geo_postgis` | 3.7.1 | PostGIS types for Ecto/Ash; spatial indexes and radius queries |
| `ex_cldr` + `ex_cldr_numbers` | 2.47.5 / 2.38.3 | German number and € formatting — `1.450,00 €`, not `1450.0` |
| `gettext` | 1.0.2 | Ships with Phoenix; German is the primary locale, not an afterthought |
| `nimble_csv` | 1.3.0 | Hand-digitised Mietspiegel tables arrive as CSV |

**Geocoding is the one genuinely awkward dependency, and the answer is to avoid it.**
The `geocoder` package (2.2.2) fronts Nominatim, but the OSM Foundation's usage policy
is explicit: *"an absolute maximum of 1 request per second"*, and *"periodic requests
from apps are considered bulk geocoding and as such are strongly discouraged."* A
crawler geocoding every new listing is exactly the described anti-pattern.

Three better routes, in order of preference:

1. **Do not geocode — join on the address string.** Berlin's Wohnlagen WFS is already
   keyed by *address*, and Berlin publishes its official address register (RBS) as open
   data. Normalising `Müllerstraße 12, 13353` and matching it against an address table
   is a string problem, not a geocoding problem, and it is both free and exact.
2. **Self-host Photon or Nominatim** as a container if coordinates are genuinely needed
   for radius search. No rate limit, no policy question.
3. **A commercial geocoder** only if 1 and 2 fail.

PostGIS is worth enabling in Phase 1's database even though nothing uses it yet —
adding the extension later to a live database is a migration nobody enjoys.

---

## 5. Bootstrap sequence

Nothing below is run yet. This is the plan to execute after the proposal is accepted.

**Layout: decided.** The Elixir app takes the repository root; the Node crawler is
archived in `.references/`. `mix igniter.new` creates a subdirectory by default, so
generate into a temp directory and move the tree in — that cannot scatter files into
`.github/` or `docs/` if a generator misbehaves.

```bash
# 0. Elixir/OTP via .tool-versions (mise/asdf) — pin explicitly, do not inherit
mix archive.install hex phx_new
mix igniter.new find_me_a_flat --with phx.new --install ash,ash_postgres,ash_phoenix

cd find_me_a_flat

# 1. Background jobs
mix igniter.install ash_oban

# 2. Admin authentication — pin the stable 4.x line, not the v5 RC
mix igniter.install ash_authentication ash_authentication_phoenix
mix igniter.install ash_admin          # mount INSIDE the authenticated scope

# 3. Telegram, HTTP, parsing  (ex_gram has no igniter installer — plain deps)
mix igniter.install ex_gram req floki

# 4. Domains + resources — generated, then hand-edited
mix ash.gen.domain FindMeAFlat.Accounts
mix ash.gen.domain FindMeAFlat.Searches
mix ash.gen.domain FindMeAFlat.Listings
mix ash.gen.domain FindMeAFlat.Portals
mix ash.gen.domain FindMeAFlat.Reference   # reserved, empty in Phase 1

mix ash.gen.resource FindMeAFlat.Accounts.Subscriber \
  --default-actions read,create,update \
  --uuid-v7-primary-key id \
  --attribute telegram_chat_id:integer:required \
  --extend postgres

mix ash.gen.resource FindMeAFlat.Portals.Portal        --uuid-v7-primary-key id --extend postgres
mix ash.gen.resource FindMeAFlat.Portals.SelectorSet   --uuid-v7-primary-key id --extend postgres
mix ash.gen.resource FindMeAFlat.Searches.Search       --uuid-v7-primary-key id --extend postgres
mix ash.gen.resource FindMeAFlat.Searches.SearchPortal --uuid-v7-primary-key id --extend postgres
mix ash.gen.resource FindMeAFlat.Listings.Listing      --uuid-v7-primary-key id --extend postgres
mix ash.gen.resource FindMeAFlat.Listings.Delivery     --uuid-v7-primary-key id --extend postgres

# 5. Migrations — read the generated SQL before running it
# Enable postgis + vector in this first migration even though Phase 1 uses neither —
# adding extensions to a live database later is a migration nobody enjoys.
mix ash.codegen initial_schema
mix excellent_migrations.check_safety
mix ash.migrate

# 6. Harness expectation from .agents/README.md
mix usage_rules.sync --yes
```

`--extend postgres` and `--uuid-v7-primary-key` flags should be confirmed against the
installed `ash_postgres` version at run time; Ash's generator surface moves, and this
sequence is a plan, not a transcript.

---

## 6. Suggested slices

Vertical, each independently shippable and verifiable.

| # | Slice | Done when |
|---|---|---|
| 1 | Skeleton + Repo + Oban + health endpoint | `mix phx.server` boots, `/health` returns 200 |
| 2 | `Subscriber` upsert on `/start` | Messaging the bot from two different accounts creates two rows, no config file touched |
| 3 | `Portal` + `SelectorSet` seeded from `CURRENT-SYSTEM.md` §8 | Seeds load; `ash_admin` lists them |
| 4 | Parser + fixtures for kleinanzeigen | Stored HTML fixture yields ≥25 listings, all with non-nil id/title/url |
| 5 | `HttpFetcher` + `PortalGate` | Live fetch of kleinanzeigen returns 200; two concurrent searches produce one fetch |
| 6 | Crawl → upsert → `Delivery` → Telegram | A real new listing arrives in Telegram, once, correctly HTML-escaped |
| 7 | Setup wizard (`/new`, `/list`, `/pause`, `/delete`) | A new user completes setup from a phone with no help |
| 8 | Ports: immowelt, immosuchmaschine, wg-gesucht | Fixture test per portal passes against re-derived selectors |
| 9 | Health: `consecutive_empty_runs` → `:broken` + notify | Pointing a portal at a 410 URL produces a Telegram warning within 3 cycles |
| 10 | Weekly live-drift CI job | Job fails when a portal's live HTML stops matching its `SelectorSet` |

Slice 4 before slice 5 is deliberate: parsing is testable offline against a saved
fixture, and getting it right first means the live-fetch slice has exactly one new
variable.

---

## 7. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Selectors must be re-derived by hand for 4 portals | **high — this is the real work** | Slices 4 and 8; fixtures make it verifiable rather than hopeful |
| ImmoScout24 stays unavailable | medium | Ship degraded and visible; browser tier is a separate bet |
| Immowelt pagination never solved | low | Page 1 at a 5-minute interval covers a newest-first feed |
| Ash learning curve stalls the rewrite | medium | Repo already carries `writing-ash-code` and `build` skill references |
| Portals break again in 6 months | **certain** | Selectors as data + drift CI + `:broken` health state — this is the point |
| RC pins (`req`, `ash_authentication`) | low | Pin stable lines; revisit at v5 GA |
| No mature Elixir headless browser | medium | Sidecar service if the tier is bet on |
| Scope creep from "other ideas" | medium | Ship slices 1–7 before opening the LiveView surface |
