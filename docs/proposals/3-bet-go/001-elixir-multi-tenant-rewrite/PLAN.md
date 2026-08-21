# Elixir Multi-Tenant Rewrite — Implementation Plan

> **For agents:** Use `build`; stop when PLAN and CONCEPT conflict.

**Outcome:** One deployment serves several people, each with their own searches set up
entirely from Telegram, receiving new listings from four portals within one crawl
interval — and announcing loudly when a portal stops working.

**Epic:** [#29](https://github.com/xu-chris/findmeaflat/issues/29)
**Sub-issues:**

| Slice | Issue | Mode |
|---|---|---|
| S1 | [#31](https://github.com/xu-chris/findmeaflat/issues/31) | AFK |
| S2 | [#32](https://github.com/xu-chris/findmeaflat/issues/32) | AFK |
| S3 | [#33](https://github.com/xu-chris/findmeaflat/issues/33) | AFK |
| S4 | [#30](https://github.com/xu-chris/findmeaflat/issues/30) | HITL |
| S5 | [#34](https://github.com/xu-chris/findmeaflat/issues/34) | AFK |
| S6 | [#35](https://github.com/xu-chris/findmeaflat/issues/35) | AFK |
| S7 | [#36](https://github.com/xu-chris/findmeaflat/issues/36) | AFK |
| S8 | [#37](https://github.com/xu-chris/findmeaflat/issues/37) | AFK |
| S9 | [#38](https://github.com/xu-chris/findmeaflat/issues/38) | AFK |
| S10 | [#39](https://github.com/xu-chris/findmeaflat/issues/39) | AFK |
| S11 | [#40](https://github.com/xu-chris/findmeaflat/issues/40) | AFK |
| S12 | [#41](https://github.com/xu-chris/findmeaflat/issues/41) | AFK |
| S13 | [#42](https://github.com/xu-chris/findmeaflat/issues/42) | AFK |
| S14 | [#43](https://github.com/xu-chris/findmeaflat/issues/43) | AFK |
| S15 | [#44](https://github.com/xu-chris/findmeaflat/issues/44) | HITL |
| S16 | [#45](https://github.com/xu-chris/findmeaflat/issues/45) | AFK |

**Owner/complexity:** Chris. Yellow — 16 slices, ~100k context each.
**Architecture:** Five Ash domains over Postgres. Oban owns scheduling and retries; a
`Crawling` namespace owns sequencing and no data. Portal extraction lives in adapter
modules behind a behaviour, proved against committed HTML fixtures. The only
unauthenticated public route is the Telegram webhook.
**Relevant stack:** Elixir 1.20.1/OTP 28.5, Phoenix 1.8, Ash 3.x + AshPostgres +
AshOban, Oban OSS, ex_gram, Req + Floki, PostgreSQL 18.

---

## Decisions and Evidence

This plan was written after four independent reviews (domain, operational, pragmatic,
code-organisation). Where they converged, the finding is treated as established; where
they split, the decision and its loser are recorded.

### Corrections to the accepted design

**1. `consecutive_empty_runs` would have caught one failure of six, not all six.**
`TARGET-ARCHITECTURE.md` gated it on *zero cards from a 200*. This proposal's own status
table shows immonet 403, immoscout 401, immowelt 410, kleinanzeigen 410 — four portals
that never return 200, so the counter never moves — and immosuchmaschine returning 200
with 22 cards whose IDs all collapse to `NaN`, which is not zero. Only wg-gesucht is a
clean 200-with-zero-cards. **Health is driven by terminal fetch outcomes and per-field
fill rates instead** (S13).

**2. Nothing defined what "new" means, and the obvious definition loses data silently.**
Three reviewers converged here. If "new" means *the upsert inserted rather than updated*,
that is a property of the run, not the database — so a `:crawl` job killed between
upserting listings and creating deliveries (deploy past `shutdown_grace_period`, Oban
`Lifeline` rescue, pool timeout) re-runs, upserts into existing rows, computes zero new
listings, and **completes successfully**. The batch is gone, with no `Delivery` row to
count and nothing for health to see. That is `CURRENT-SYSTEM.md` §11.3 reborn one stage
earlier, in the system whose whole justification is not doing it.

**Two complementary rules, both in S7:**
- `Search.matches_from` (utc_datetime_usec, set on activation and un-pause) bounds the
  start, so a new search does not match a year of stored listings and fire thousands of
  messages.
- "Undelivered" means **no `Delivery` row exists** for `{subscriber, listing}` within a
  bounded lookback window — a LEFT JOIN on a separate pass, not a flag from the crawl.
  A crashed crawl then self-heals next cycle, and the lookback is an explicit operator
  control instead of an accident.

Matching is triggered by the **listing upsert**, never by the crawl job that found it —
otherwise a listing discovered by subscriber A's crawl never reaches subscriber B, which
under a shared portal is the normal path, not an edge case.

**3. `SelectorSet` as database rows is cut from Phase 1.** Two reviewers argued to cut it
and a third showed why: of the four in-scope portals, exactly **one** (kleinanzeigen) is
expressible as selector + attribute + cast. Immowelt needs a `split("classified-card-mfe-")`.
Immosuchmaschine needs a regex URL extraction out of a JS attribute plus `€ `/`,-` price
splitting. wg-gesucht needs a `" | "` split, a `" in "` address extraction, and a
22-parameter URL builder. A data format that covers one portal in four is not a data
format — and the "repair from a phone, no deploy" property it exists for evaporates.

The operational objection is decisive for an unattended system: with selectors in rows,
production parsing behaviour is **not in git**. CI asserts the seeded selector while
production uses an edited one; there is no review, no local reproduction, and no answer
to "which selector parsed this listing".

**Selectors live as module attributes in `Portals.Adapter.*`, covered by fixture tests.**
Reversal is cheap in both directions: seeding rows from module constants is a short
script if portals ever start breaking monthly rather than a few times a year. *Loser:
the domain review, which wanted `SelectorSet` central and would have proved it on
kleinanzeigen first.*

**4. One home per concept.** `Search` carried `max_rent`/`min_size`/`min_rooms`/
`wanted_districts`/`blacklist_terms` as columns **and** `Filter` rows of the same kinds.
A concept that exists twice gets evaluated twice and the two disagree. **Columns only;
`Filter` is cut from Phase 1.** The Phase 3 filter that motivated the resource
(`percent_over_reference`) arrives as a nullable column plus a backfill — trivial at
this scale.

Same reasoning cuts **`PortalHealth`** as a resource: it had no column not derivable
from the watch rows, and three homes for "is Immowelt ok" (`Portal.state`,
`SearchPortal.state`, `PortalHealth`) means two of them drift. Health is an aggregate on
`Portal`.

**5. `SearchPortal` is renamed `Watch`.** Called a join, it attracted foreign keys and
nothing else; in fact it carries the URL, the schedule, the failure state and the error —
it is the unit of scheduling, health and notification. A **`Watch`** is a standing
instruction to check one portal for one search.

**6. The `Fetcher` behaviour is cut; `Transport` is the real seam.** `Fetcher` had one
implementation in Phase 1, and `STACK.md` §3 already concludes the browser tier would be
"a small sidecar service … called over HTTP" — which is a second *transport*, not a
second fetcher. `Transport` is exactly the seam `test-examples.md` permits doubling.

**7. `PortalGate` moves to `Fetching` and must shed, not block.** The architecture
contradicted itself (§5 put it in `Fetching`, §6 under `Portals.GateSupervisor`).
`Portals` is a persistence domain and should own zero long-lived processes. And a
blocking `GenServer.call` with twenty due watches on one portal parks ten Oban jobs for
up to 100 seconds each **while holding database connections** — head-of-line blocking
that starves every other portal and can starve the webhook. It returns
`{:error, :gated, ms}`, and the job snoozes.

**8. Quiet hours are cut.** They contradict the only thing this product is for. The value
proposition is latency — *"message #3 instead of #47"*. A listing found at 02:00 and
delivered at 08:00 makes the user message #200: strictly worse than not sending, because
it spends attention on a flat that is gone. `/pause` already expresses "stop messaging
me", as a decision rather than a schedule inferred from a timezone we had to ask for.

### Established by evidence, not opinion

- Four of six portals are unreachable or renamed; only four are in scope
  (`CRAWL-DIAGNOSIS.md`).
- Immowelt's next-page control is a `<button>` with no `href`; `?sp=2` and `?page=2` both
  return page 1. Page 1 only, by decision.
- Elixir 1.20.1 / OTP 28.5 and `elixir/v1.20.1-otp-28.zip` verified present on
  `builds.hex.pm`.
- The Node crawler is archived in `.references/`; `lib/` is free.

## Boundaries and Non-goals

Excluded by the accepted Bet: ImmoScout24 and any browser tier, Immonet, Immowelt
pagination, all enrichment (Mietspiegel, buildings, providers, credibility, demand
data), any user-facing web UI, public hosting for strangers.

Excluded by this plan, in addition: `SelectorSet` rows, `Filter` rows, `PortalHealth`,
the `Fetcher` behaviour, quiet hours.

**Open against the Bet:** the Bet names "an authenticated admin surface". With
`SelectorSet` cut, its main justification — the selector-repair console — is gone, and
two reviewers argued the remaining value does not pay for `ash_admin` (which exposes
destructive actions on every resource by default), `ash_authentication`,
`ash_authentication_phoenix`, a login surface and four more dependencies patched
unattended for months. **S13 keeps it, sized minimally and ordered last.** If it should
be cut, cut it there — that is a decision for Chris, not for this plan.

## Existing System Context

| Path | What it is |
|---|---|
| `.references/lib/sources/*.js` | the four portals' selectors — the port's source of truth |
| `.references/lib/flatfinder.js` | the pipeline shape to *not* reproduce |
| `.references/lib/utils.js` | `isOneOf` — carries the unescaped-regex and empty-array bugs |
| `CURRENT-SYSTEM.md` §8 | per-portal selector table |
| `CRAWL-DIAGNOSIS.md` | per-portal live probe evidence, dated 2026-08-20 |
| `.github/workflows/ci.yml` | stack-detecting; the Elixir lane switches on when `mix.exs` lands |

**Reading a portal fixture is a sizing error.** They are 250 KB–1.5 MB. Work by `rg`
against the file and `Floki` in IEx; never `Read` one whole.

---

## Vertical Slices

### S1 — Foundation and spine
**Acceptance:** `mix phx.server` boots from the repo root; `GET /healthz` returns 200
only when the Repo checks out a connection **and** Oban's cron has enqueued within the
last two minutes, 503 otherwise; `mix ci` green in CI.
**Red:** `health_controller_test.exs` asserts 503 when the last cycle is stale — the
assertion that catches a health check wired to "the app is up" rather than "the work
happened".
**Green:** generators, five domains (`Reference` empty), extensions migration.

**Extensions — neither, and the reasoning that got there is worth keeping.** The design
said enable `postgis` *and* `vector` in the first migration, on the grounds that adding
one to a live database later is painful. The pragmatic review disagreed: *"the actual
cost is not the migration at all — it is that the Postgres server must ship the extension
binaries."*

That was accepted for `postgis` and, wrongly, not for `vector`, which was kept as
"free, the dev image carries it". **It was not free.** Within the hour CI failed with
`extension "vector" is not available`, and the fix pinned `pgvector/pgvector:pg18` into
both `docker-compose.yml` and `ci.yml`, plus the cloud setup script — coupling every
environment to an extension nothing uses, for a Phase 5 roadmap item that is not bet on
and whose dependency (`ash_ai`) is not installed.

**Enable `citext` only** — Ash's `:ci_string` uses it and it ships with stock Postgres.
`vector` and `postgis` each arrive in the slice that first needs one, with a test that
exercises it. Deferring costs nothing: `CREATE EXTENSION` is one line whenever it runs.

**Local database:** `docker compose up -d` → stock `postgres:18-alpine` on **5434**,
user/password `postgres`. Not 5433: that port is commonly held by another project's test
database on a developer machine, and pointing migrations at the wrong server is silent
and expensive.


**Verify:** `mix ci`
**Reads:** `STACK.md` §5, `.github/workflows/ci.yml`
**Uncertainty:** `mix igniter.new` writes a subdirectory — generate to a temp dir and
move the tree, so a misbehaving generator cannot scatter into `.github/` or `docs/`.
**Depends on:** none
**Excludes:** any domain content. A slice whose demo is "the server boots" demos nothing;
the health endpoint that can say *no* is the demo.

**S1 also creates four empty anchor modules** referenced from the spine and owned by
later slices: `fetching/supervisor.ex` (→S3), `bot/supervisor.ex` (→S5),
`find_me_a_flat_web/plugs/telegram_webhook.ex` (→S5), `crawling/scheduler.ex` (→S8).
Every Phase 1 config key is declared here. **A later slice needing a new config key is a
signal its seam was drawn wrong.**

### S2 — Extraction and the kleinanzeigen adapter
**Acceptance:** a committed fixture yields ≥25 listings with non-nil `external_id`,
`title`, `url`, `price_cents`, `description`, `image_urls`; one deliberately mangled card
is counted as an error without taking the other 32; the result carries a success count
**and a per-field fill rate**; a stored WAF challenge body classifies
`{:error, :unrecognisable}` and an empty-but-valid results page classifies
`{:ok, :no_results}`.
**Red:** three page classes, three distinct results. The three-way split is the domain
requirement: "nothing new", "genuinely no results" and "we cannot read this page" are
three facts, and one integer cannot carry them.
**Verify:** `mix test test/find_me_a_flat/portals/`
**Reads:** `.references/lib/sources/kleinanzeigen.js`, `CURRENT-SYSTEM.md` §8
**Uncertainty:** ~~none — every kleinanzeigen selector was verified still matching.~~
**That was false.** The verification was a substring `grep`, not a CSS match; three
selectors were dead (container, price, size/rooms). See the correction at the top of
`CRAWL-DIAGNOSIS.md`. Assume the same for any portal whose selectors were "verified"
the same way — S11 especially.
**Depends on:** S1
**Why fill rate:** per-card isolation is a *silence generator* without it. When immowelt
changes its price markup, 32 of 32 cards still parse, `price_cents` is nil on all 32, no
counter moves, and users simply stop seeing prices.

### S3 — Fetching: outcomes as values, a gate that sheds
**Acceptance:** `Fetching.fetch/2` returns `{:ok, %Page{}}` or one of
`{:error, :challenged | :gone | :not_found | :rate_limited | :timeout | :transport_error}`,
each with a declared retry disposition; `:challenged` and `:gone` are **cancel, not
retry**; two concurrent callers on one portal are paced, and the second gets
`{:error, :gated, ms}` rather than blocking.
**Red:** a doubled `Transport` replays a 200, a 410, a truncated body and a challenge.
**Verify:** `mix test test/find_me_a_flat/fetching/`
**Reads:** `.references/lib/scraper.js`, `CRAWL-DIAGNOSIS.md` §2, §9
**Depends on:** S1
**Why cancel:** Oban's default `max_attempts: 20` against a 401 challenge means twenty
further requests to a site actively telling us to stop — per watch, per cycle. That is
how a 410 becomes an IP ban.
**Seam:** `Portals` hands `Fetching` a plain `{slug, min_seconds_between_requests}` list
once at boot. `Fetching` never aliases `Portals.Portal` at runtime.

### S4 — Spike: a real listing in a real Telegram chat
**Acceptance:** one mix task fetches the live kleinanzeigen URL, parses with S2, formats
as `parse_mode: "HTML"`, sends, prints `message_id`. A German title containing `_` and
`<` arrives intact.
**Verify:** `mix find_me_a_flat.spike --portal kleinanzeigen --chat-id $CHAT_ID`
**Depends on:** S2, S3
**Why here:** this is the Bet's Good Enough in miniature, at slice four rather than
slice ten, and it retires every non-schema unknown at once — does a modern header set get
a 200 where the 2017 UA got 410, does `ex_gram` send, does HTML escaping survive German
titles. The seen-set is an in-memory `MapSet` and the chat id is a CLI argument: both are
deliberately throwaway. The fetcher, formatter and ex_gram wiring survive; ~20 lines die.
**Excludes:** persistence of any kind.

### S5 — Subscribers, and an idempotent front door
**Acceptance:** two Telegram accounts each `/start` → two `Subscriber` rows with distinct
`telegram_chat_id`; the same `update_id` replayed three times creates one; the webhook
verifies `X-Telegram-Bot-Api-Secret-Token`, enqueues, and returns 200 in constant time
without touching a portal; locale from `language_code`; the consent decision stored with
its wording version and timestamp. No config file anywhere in the repo.
**Verify:** `mix test test/find_me_a_flat/accounts/ test/find_me_a_flat_web/telegram_webhook_test.exs`
**Reads:** `.references/lib/notify.js`, `DEMAND-DATA.md` §4, §6
**Depends on:** S1
**Why idempotency now:** Telegram redelivers on timeout or non-2xx. Synchronous handling
turns one `/start` into three subscribers and later one `/new` into three searches —
tripling crawl volume against portals already blocking us. Retrofitting `update_id`
dedupe means auditing every handler for side effects.
**Why the consent record now:** "we asked in German at some point" is not a defence; a
versioned row is. Retrofitting means asking every existing user again.
**Naming:** the operator is **not** a `Subscriber`. One operator, many subscribers, no
shared attribute. An `Operator` actor must never satisfy a `Subscriber` policy — assert it.

### S6 — Searches and Watches, created by `/addurl`
**Acceptance:** `/addurl <url>` detects the portal by host, validates, creates a `Search`
plus one active `Watch`; `/list` renders it; `/pause` flips state; `/delete` soft-deletes;
a search is `Ash.Error.Forbidden` for any other subscriber.
**Verify:** `mix test test/find_me_a_flat/searches/`
**Reads:** `.references/lib/utils.js`, `.references/conf/config.json.example`
**Depends on:** S5
**Why `/addurl` before the wizard:** pasting a portal URL is the product's best idea
(`CURRENT-SYSTEM.md` §10.1) and the only creation path that works for every portal
regardless of whether its URL can be constructed. The wizard then improves a working
path instead of being the only door.
**The forbidden-read test is not optional.** One deployment serves everyone and policies
are the only separation; a policy regression is otherwise silent.

### S7 — Listings, deliveries, and what "new" means
**Acceptance:** a card upserts on `{portal_id, external_id}` with `description` and
`image_urls` in full; running twice creates N rows then 0; **a new search matches nothing
older than its `matches_from`**; a listing discovered by subscriber A's crawl produces a
`Delivery` for subscriber B whose search also matches; running the matcher twice
concurrently creates no duplicates; a crawl killed after upsert self-heals next pass; the
**first run of a new `Watch` primes — records, does not deliver**.
**Verify:** `mix test test/find_me_a_flat/listings/`
**Reads:** `.references/lib/flatfinder.js` `run()`, `.references/lib/utils.js` `isOneOf`
**Depends on:** S6
**This is the most important slice in the plan.** It carries both correction #2 rules.
**Why priming:** without it, completing the wizard fires 32 messages in ten seconds,
trips Telegram's rate limit, and the user's first experience of the bot is spam.
**Do not reproduce** `isOneOf`'s bugs: terms must be regex-escaped, and an empty
blacklist must block nothing (today `\b()\b` blacklists everything).

### S8 — Crawling: the durable pipeline
**Acceptance:** a fixture body through a doubled transport and a doubled Telegram
produces listings, deliveries and exactly one correctly escaped message per subscriber;
the job is idempotent under kill-and-rerun; every terminal outcome writes its class,
`last_error` and timestamps.
**Verify:** `mix test test/find_me_a_flat/crawling/`
**Depends on:** S3, S7
**Boundary, non-negotiable:** `FindMeAFlat.Crawling` owns sequencing and **no data** —
zero Ash resources, zero `Repo` calls, zero `Ash.read/create`. It may only call domain
code interfaces, and it is the only module permitted to touch more than one domain in a
function. The inverse holds too: **no Ash resource, change or AshOban trigger may call
`Fetching` or `Bot`.** A `Change` that fetches HTML is `lib/flatfinder.js` rebuilt inside
a DSL, which `architecture.md` forbids by name.

### S9 — Delivery: four failures, four responses
**Acceptance:** 429 reads `retry_after` and snoozes, leaving the row `pending`; 403
"bot was blocked" marks the subscriber `:blocked` and stops crawling their searches;
any other error leaves `:failed` with `attempts` incremented, **never `:sent`**;
deliveries older than the max age become `:suppressed` with one summary line.
**Verify:** `mix test test/find_me_a_flat/delivery/`
**Depends on:** S8
**Why suppression:** after a three-day outage the bot finds 900 undelivered matches,
sends them all, gets 429'd, and the user blocks it — turning a recoverable outage into a
lost user.
**Pacing:** `:deliver` concurrency 1 plus snooze-on-429 is sufficient below ten
subscribers. A token bucket for Telegram's 30/s global limit is load that does not exist.

### S10 — immowelt adapter · S11 — immosuchmaschine adapter · S12 — wg_gesucht adapter
Three slices, fully parallel, sharing no file.
**Acceptance (each):** fixture yields the expected card count with non-nil
id/title/url/price; live probe green.
**Verify:** `mix test test/find_me_a_flat/portals/adapter/<slug>_test.exs`
**Depends on:** S2
- **S10 immowelt** — all selectors verified still matching; needs the
  `classified-card-mfe-<id>` prefix strip. **Carries the plan's biggest unknown**
  (below): record `url_strategy` as `:constructed` or `:pasted_only` from what is
  actually achievable.
- **S11 immosuchmaschine** — **more broken than first diagnosed.** CSS-verified: the
  container matches 17 (not 22), `data-expose-id` is dead (→ `[data-id]`, 10), **and
  `.data_title div.objectLink` is also dead** — missed because its 151 substring hits
  come from unrelated markup. Price 10, size 10, rooms 8 against 17 containers, so the
  page drifted further than one rename. **Expect to re-derive the whole selector set,
  not patch one field.** Still needs the `data-js` regex URL recovery and price parsing
  that does not reject the batch on one odd format.
- **S12 wg_gesucht** — full redesign: `.wgg_card.offer_list_item`,
  `id="liste-details-ad-<id>"`, plus the 22-parameter URL builder for both flat types.
  The only adapter whose `search_url/1` does real work — which is why the callback exists.

**Registry by convention, not by table:** adapters resolve as
`Module.concat(Portals.Adapter, Macro.camelize(slug))`. Adding a portal adds files and
edits no shared map — the only reason these three are cleanly parallel. Seeds load by
`Path.wildcard`, so each portal ships its own seed file.

### S13 — Health, edge-triggered
**Acceptance:** four seeded failures — 410, 401-challenge, 200-with-zero-cards, and
200-with-cards-but-null-prices — each flip the portal and produce **exactly one** Telegram
message per transition; a genuinely narrow search returning an empty results page flips
nothing; a dead pasted URL marks only that `Watch` `:url_dead` and messages only its
owner.
**Verify:** `mix test test/find_me_a_flat/portals/health_test.exs`
**Depends on:** S8, S10, S11, S12
**Two distinct facts, two owners:** "the portal changed its markup" is per-portal, the
operator's problem, fixed in an adapter. "Your saved URL is dead" is per-watch, the
user's problem, fixed by re-pasting. `CRAWL-DIAGNOSIS.md` §3 documents both happening on
immowelt *simultaneously* — 200 with every selector matching, while every saved URL
returned 410. One state cannot say both.
**Why edge-triggered:** a broken portal on a 5-minute interval over a weekend is 576
identical alerts, which trains the operator to mute the channel — and a muted alert
channel is indistinguishable from none.

### S14 — Deadman heartbeat, operator digest, and drift CI
**Acceptance:** a `:maintenance` job pings an external dead-man URL **only if** a crawl
cycle completed in the window; a daily Telegram digest reports per-portal cards parsed,
deliveries sent/failed/pending, oldest pending delivery age, and discarded Oban jobs; a
weekly CI job re-fetches each portal and fails when live HTML stops matching.
**Red:** assert the ping is **not** sent when the last completed cycle is stale — the only
assertion that catches a heartbeat wired to "the job ran" instead of "the work happened".
**Verify:** `mix test test/find_me_a_flat/maintenance/` and `mix portal.drift --all`
**Depends on:** S13
**Why:** every health mechanism in S13 is computed by the process that fails. The
failures it cannot report are the total ones — queues misconfigured on the prod path,
cron missing from the plugin list, pool exhausted, container OOM-looping, host off. In
every one, the user's experience is byte-identical to the year the predecessor spent
dead. Replacing "silent zero listings" with "loud `:broken`" fixes one failure shape and
leaves the whole outage class untouched. ~40 lines, no metrics stack.
**Drift CI** is the mechanism `CRAWL-DIAGNOSIS.md` §8.5 says would have caught all five
fixable breakages within a week. A fixture without a drift job rots into a green test
over a dead portal — precisely the failure this rewrite exists to kill.

### S15 — Setup wizard
**Acceptance:** someone who has never opened a terminal completes `/new` from a phone and
has a live search; `/status` answers "is it quiet or is it broken?"; a deploy mid-wizard
does not lose the conversation.
**Verify:** `mix test test/find_me_a_flat/bot/wizard_test.exs`, then one real person on a
real phone
**Depends on:** S6, S12
**Wizard state lives in Postgres keyed by `chat_id`**, never in a GenServer or ETS.
Otherwise every deploy strands every in-progress onboarding at an unresumable step and
the user simply stops — a failure with no error and no log line.
**Ordered here** because `/addurl` already makes the tool usable, and because the wizard
can only be honest about which portals it can construct URLs for once S10–S12 have
recorded that as fact.

### S16 — Admin surface *(see Boundaries — candidate for cutting)*
**Acceptance:** `/admin` behind login as a single seeded operator; unauthenticated
`GET /admin` returns 302.
**Verify:** `mix test test/find_me_a_flat_web/admin_auth_test.exs` — assert the **302**,
not the 200. The security assertion is the point.
**Depends on:** S1
**`ash_admin` must be mounted inside the authenticated scope**, never beside it: it
exposes destructive actions on every resource by default.

---

## Phase Matrix

| Phase | Kind | Slices | Parallel | Blocked by | Mode |
|---|---|---|---|---|---|
| 1 | Prefactor | S1 | — | none | AFK |
| 2 | Deliver | S2, S3, S5 | yes — `portals/`, `fetching/`, `accounts/`+`bot/` | S1 | AFK, AFK, AFK |
| 3 | Integrate | S4 | — | S2, S3 | HITL — needs a live token and a real chat |
| 4 | Deliver | S6 | — | S5 | AFK |
| 5 | Deliver | S7 | — | S6 | AFK |
| 6 | Integrate | S8 | — | S3, S7 | AFK |
| 7 | Deliver | S9 | — | S8 | AFK |
| 8 | Expand | S10, S11, S12 | yes — one adapter dir + one fixture each | S2 | AFK, AFK, AFK |
| 9 | Deliver | S13 | — | S8, S10, S11, S12 | AFK |
| 10 | Deliver | S14, S16 | yes — `maintenance/` vs `_web/` | S13 / S1 | AFK, AFK |
| 11 | Deliver | S15 | — | S6, S12 | HITL — the demo is a person on a phone |

**Declared overlaps, all append-only, one line each:** each Ash domain's `resources do`
block (S1 creates, one later slice appends); `bot/router.ex` (S5 and S15);
`crawling/crawl_worker.ex` (S8 and S13).

---

## Verification Matrix

| Concern | Public seam | Check | Expected signal |
|---|---|---|---|
| A portal still parses | `Portals.Adapter.<Slug>.parse/1` | fixture test | ≥N cards, non-nil id/title/url/price |
| A portal broke | `Portals.health/1` | seeded 410/401/empty/null-price | exactly one notice per transition |
| Tenancy holds | `Searches.get_search/2` | other subscriber as actor | `Ash.Error.Forbidden` |
| Nothing is lost on crash | `Crawling.CrawlWorker` | kill after upsert, re-run | deliveries appear next pass |
| No flood on a new search | `Listings.match/1` | search with `matches_from` now | zero deliveries for old listings |
| No duplicate sends | `Delivery` unique index | run matcher twice concurrently | one row |
| Send failure ≠ seen | `Delivery.state` | simulated 500 | `:failed`, retried, never `:sent` |
| The system is alive | dead-man URL | stop the app | alert within one interval |
| Fixtures still match live | `mix portal.drift --all` | weekly CI | non-zero exit on drift |

## Rollout, Observability, and Rollback

The Node crawler is archived, so there is no side-by-side running: **rollback is
redeploying the previous image tag**, which must be true from S1. `publish.yml` already
tags and pushes on every push to master, gated on a secret scan.

Observability is deliberately three cheap things, not a metrics stack: `/healthz` that
can say no (S1), the dead-man ping and daily digest (S14), and edge-triggered portal
notices (S13).

## Execution Frontier

**Unblocked now:** S1 only.
**After S1:** S2, S3, S5 in parallel — disjoint directories.
**After S2:** S10, S11, S12 in parallel — one adapter and one fixture each.

## Completion Handoff

Every slice: `mix ci` green, moduledocs on new public modules, the sub-issue closed with
its verification output pasted. At the end: reconcile PLAN against what was built, record
Green completion evidence in `CONCEPT.md`, move the card to `4-done`, and write the first
ADR for any decision above that survived contact — the "what new means" rule in S7 is the
strongest candidate.
