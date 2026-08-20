# Elixir Multi-Tenant Rewrite

Evidence summary: Live probes of all six portals on 2026-08-20 show five distinct
failure modes, only two of which are stale selectors — Immonet has been sunset into
Immowelt behind DataDome, ImmoScout24 returns 401 behind an AWS WAF challenge, Immowelt
and Kleinanzeigen URLs return 410 after scheme and domain changes, and wg-gesucht was
redesigned. Four of six runtime dependencies were last published between 2014 and 2019,
and the Docker base image (`node:14-alpine`) has been end-of-life since 2023-04-30.
Separately, `daten.berlin.de` publishes address-level Wohnlagen for the Berliner
Mietspiegel under `dl-de/zero-2.0`, and Dortmund publishes a complete 2,443-row
Mietspiegel table via API — making an official fair-rent comparison buildable today for
two cities. Full evidence in `CRAWL-DIAGNOSIS.md` and `OPEN-DATA.md`.

## Problem Statement

Three problems, one architecture behind all of them.

**The crawler stopped working, silently.** Five of six portals return nothing usable,
and they have failed in five different ways over roughly a year. The system cannot tell
the difference between "no new flats" and "the portal returned 410 Gone" — both surface
as `Found 0 new listings`. Every one of these breakages was invisible for months.
Open issue #20 (*Immowelt pagination does not work*, filed 2022-07-24) has never been
fixed because it is not fixable in the current stack: Immowelt's next-page control is a
React `<button>` with no `href`, and x-ray's `.paginate()` requires a link attribute.

**One deployment serves exactly one person.** The Telegram chat ID is read from
`conf/config.json` at import time, and the seen-listing set is a single global array in
`db/listing.json`. Both are process-wide singletons. Serving a second person requires a
second process, a second config file and a second volume — so five people means five
instances, five times the crawl volume against portals that are actively blocking bots,
and five times the maintenance. This is the stated day-to-day pain.

**Setup requires a terminal.** Before first run a user must create a bot with BotFather,
message it, run `curl .../getUpdates`, extract a numeric chat ID from JSON, paste it
into a config file, assemble portal search URLs by hand, and bind-mount the file into a
container. None of it is doable from a phone. The mechanical cause is that `tg-yarl`
(last published 2016-08-09) is send-only — the bot cannot receive messages, so it can
never learn a chat ID at runtime.

**And the ambition is larger than a repair.** The tool should tell German renters things
the portals will not: whether a rent is legal and fair against the official Mietspiegel,
who actually manages the building and what their phone number is, and how to reach them
before becoming message #47 in a flooded inbox.

## Decision Made

The card remains in `1-draft` — no Shape Go or Bet Go has been recorded. Chris has,
however, settled several questions that were open in the first draft, and those are
recorded here as decided rather than proposed:

- **Positioning: the data crawler for the German housing problem.** The notifier is the
  surface; the substance is a longitudinal cross-portal dataset — who offers what, at
  what price relative to the legal reference, through which management company, and
  who is looking for it.
- **Users get Telegram only.** No user-facing web UI, permanently. This removes user
  registration, sessions, passwords and magic links from the product entirely.
- **Admin is Phoenix/LiveView only, behind AshAuthentication**, plus `ash_admin`.
  Pinned to the stable 4.x/2.x lines, not the v5 release candidates.
- **MCP server via `ash_ai`** in the near future — authenticated by API key or OAuth 2.1,
  which is the second reason AshAuthentication is load-bearing.
- **Mietspiegel: current edition only.** Berlin's historic Wohnlagen series back to 2003
  is skipped as a research capability, not a product one.
- **Credibility scoring is in scope** — rental scams are endemic on exactly these
  portals. Sequenced as Phase 4b because its strongest signal is the *negative* tail of
  the Mietspiegel deviation Phase 3 already computes. See `CREDIBILITY.md`.
- **Aggregate demand statistics are a candidate funding model** — public bodies and
  developers paying for anonymous data on when, where and for what kind of flat people
  search. Research confirms the gap is real: the BBSR already buys *supply* data
  (ImmoScout24 listings via empirica-systeme / VALUE AG) but derives *demand* from
  demographic modelling of the Zensus 2022. Nobody observes revealed search behaviour.
  Not a bet, and it cannot be one until the product has thousands of users — but it
  imposes six cheap Phase 1 design choices. See `DEMAND-DATA.md`.

**Decided: Shape Go by Chris.** His words, across the shaping conversation:
*"Lets pick that name and continue."* — keeping `FindMeAFlat` — and
*"AGPL and put the elixir app in the repo root"*, and
*"Move the node code into `.references/` since we will use it for referneces,
but won't need it anymore."*

**Decided: Bet Go by Chris** — *"create a thorough plan for implementation
first, including the tickets."* A request to plan the implementation and open
the tickets commits to building it; recorded here as the Bet Go rather than
left implicit. **If that reads it too strongly, say so and the card moves back
to `2-shape-go`.**

### Bet

**What we bet on:** Phase 1 only — a working, multi-tenant Telegram notifier.
Four portals crawling (immowelt, kleinanzeigen, immosuchmaschine, wg_gesucht),
subscribers and searches as rows, self-service onboarding in Telegram, an
authenticated admin surface, and portal breakage that announces itself.

**Good Enough:** Chris and one other person each run their own searches against
one deployment, set up entirely from a phone, and receive a correctly formatted
new listing within one crawl interval. A portal that stops parsing flips to
`:broken` and says so in Telegram within three cycles.

**Complexity: Yellow** — five Ash domains, a new external-fetch boundary, a
conversational UI, and an admin auth surface. It crosses more than one context
window and needs a plan. Expected context: 10–12 slices, roughly 100k tokens
each.

**Explicitly excluded:**
- ImmoScout24 and any headless-browser tier — configured, visibly degraded
- Immonet — deleted, the portal no longer exists
- Immowelt pagination — page 1 only, ~32 newest cards per run
- All enrichment: Mietspiegel, buildings, providers, credibility, demand data
- Any user-facing web UI, now or later
- Public multi-tenant hosting for strangers

What remains, after those decisions, is execution.

**Proposed: rewrite as a single multi-tenant Elixir application** — Phoenix, Ash,
Postgres, Oban, `ex_gram`, `Req` and `Floki` — replacing the per-user Node deployment.

The load-bearing insight is small: **every incoming Telegram update carries
`message.chat.id`.** A bot that *receives* messages never needs a chat ID configured; it
learns one per subscriber on `/start`. That single fact dissolves both the multi-tenancy
and the onboarding problem, and it is unavailable today only because the 2016 Telegram
library cannot receive.

Four structural changes follow:

- **Subscribers, searches and deliveries become rows, not config.** Listings are
  deduplicated globally on `{portal, external_id}`, so one crawl of Immowelt serves
  every subscriber — reducing request volume for N users from N× to 1×, which is both
  cheaper and materially safer against bot detection.
- **Extraction rules become data.** `SelectorSet` rows, versioned, so a broken portal
  is repaired by an admin write rather than a code edit, image rebuild and redeploy.
- **Failure becomes loud.** Per-card parsing means one malformed listing no longer
  rejects an entire source run. Zero parseable cards from a 200 response increments
  `consecutive_empty_runs`, and at threshold the portal flips to `:broken` and the
  subscriber is told in Telegram. A challenge page is detected as `{:error, :challenged}`
  rather than being read as an empty search.
- **Everything parsed is stored permanently.** The accumulated dataset — listings joined
  to Mietspiegel values, buildings and commercial providers — is what the product
  ambition rests on, and `db/listing.json` currently discards it by keeping bare IDs.
  Two fields are **unrecoverable** if not captured at crawl time and must therefore land
  in Phase 1: the full `description` and `image_urls`. A delisted scam listing takes its
  text and photos with it, and cross-portal photo reuse is the strongest scam signal
  available.

**Scope proposed for the first bet: Phase 1 only** — a working, multi-user notifier with
self-service Telegram onboarding, covering Immowelt, Kleinanzeigen, Immosuchmaschine and
wg-gesucht. Ten vertical slices in `STACK.md` §6. Immonet is deleted; ImmoScout24 stays
configured but visibly degraded.

Detail lives in `TARGET-ARCHITECTURE.md` (domain model, supervision, pipeline, surfaces),
`STACK.md` (dependencies with verified versions, generator sequence, slices),
`CURRENT-SYSTEM.md` (the behavioural contract to preserve or break deliberately),
`CRAWL-DIAGNOSIS.md` (per-portal evidence), `PRODUCT-VISION.md` / `OPEN-DATA.md`
(the enrichment ambition and its feasibility), `CREDIBILITY.md` (scam scoring signals
and their limits), `DEMAND-DATA.md` (the funding model, what the state already holds,
and the GDPR design constraints), and `QUALITY-GATES.md` (static analysis, security and
migration-safety tooling, with a staged adoption order).

## Consequences & Tradeoffs

**A rewrite does not fix crawling.** This is the most important caveat on the card.
Selectors and URLs must be re-derived by hand against live HTML for four portals in
whichever language is used. Elixir's leverage is not better parsing — Floki is not
better than x-ray at reading CSS — it is supervised isolation of many independent,
failure-prone jobs, plus a first-class path to the web UI the later phases need. If
those two things were off the table, the honest recommendation would be to fix the six
selectors in place and keep the Node app.

**Portals will break again.** Certainly, and repeatedly. The response is selectors as
data, a stored HTML fixture per portal with a contract test, a weekly CI job that
re-fetches live HTML and fails on drift, and the `:broken` health state. That mechanism
would have caught all five fixable breakages within a week of each occurring, and it is
the main thing being bought.

**ImmoScout24 is probably lost for now.** Passing an AWS WAF JavaScript challenge needs
a real browser with a matching TLS fingerprint. Elixir's headless-browser ecosystem is
the weakest part of this proposal — `playwright` is alpha, `chrome_remote_interface` was
last published in 2019, and Wallaby is a test tool. If the browser tier is bet on, the
honest shape is a Node or Python sidecar. **This is a place where the rewrite loses
ground**, and it should be named rather than glossed.

**Immowelt pagination stays unsolved**, deliberately. Page 1 gives ~32 newest-first
cards per run; at a 2–5 minute interval that is ample for a new-listing notifier.
Recorded as a scope decision, not a defect.

**Ash is a real cost.** A large DSL, generated migrations that must be read before they
run, and two dependencies (`ash_authentication`, `req`) whose newest releases are
pre-releases. It is proposed because this app is mostly policy plus background jobs —
which Ash policies and AshOban triggers express well — and because `ash_admin` provides
the selector-repair console for free. For a bot that only ever posted to Telegram, plain
Ecto contexts would be the better call.

**Two capabilities are deliberately not being built**, and this is a recommendation
against something explicitly asked for. Auto-submitting portal contact forms violates
every portal's terms, is blocked by the same WAF the crawler cannot pass, and — if the
tool becomes popular in Germany — makes inbox flooding worse for every renter including
its own users. Delayed re-sending to bump to the top of a landlord's inbox is
deliberate manipulation of message ordering and backfires socially. The legitimate
versions are stronger: a 2-minute crawl plus instant push makes the user message #3
rather than #47, a pre-filled message they send themselves measurably improves response
rates, and surfacing the Hausverwaltung's publicly-listed phone number routes around the
platform entirely. Reasoning in `OPEN-DATA.md` §6.

**GDPR draws a hard line through the provider directory.** Company Impressum data is
legally public and safe to aggregate. Private individual landlords' contact details are
personal data whose indirect collection triggers Art. 14's duty to proactively notify
each person — not satisfiable at scale. Commercial providers only.

**Scraped provenance makes supply data unsellable, and that is load-bearing for the
funding model.** Public bodies run procurement due diligence; data crawled against
portal terms fails it. VALUE AG's position rests on licensed access this project does
not have. The demand data has the opposite provenance — generated by our own users, with
their consent — which is why `DEMAND-DATA.md` recommends never trying to sell the supply
half. The uncontested opportunity and the clean chain of title happen to be the same
half.

**The demand model's blocker is scale, not law.** It needs low thousands of active
searchers in one city before anyone pays, and the sample is self-selected in ways a
statistician will spot immediately. Build the product because it is useful; the dataset
accrues as a side effect. Treating it as a revenue plan to build toward would be a
mistake.

**Mietspiegel coverage, not technology, is the constraint.** Machine-readable data
exists for Berlin (Wohnlagen only) and Dortmund (complete). Munich publishes 1994 and
2003. Hamburg, Köln, Frankfurt, Stuttgart, Leipzig and Dresden publish none. Every
other city means hand-digitising a PDF table. That is also the moat, since nobody else
wants to do it either.

**Migration is a clean break, not a port.** No data migration is needed — the old
`db/listing.json` holds only opaque IDs. **Decided: the Elixir app takes the repository
root**, and the Node crawler moved to `.references/` as read-only history. Side-by-side
running is therefore not available; the rollback story is redeploying the previous image
tag, which must be true from the first slice.
