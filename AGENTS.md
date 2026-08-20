# FindMeAFlat

Crawls German real-estate portals for new listings and notifies via Telegram.
Public repository (`xu-chris/findmeaflat`), MIT, forked from `adriankumpf/findmeaflat`.

## What this repo is right now

**A Node.js 
crawler that is largely broken, plus a written proposal to replace it with Elixir.**
Both states are real; know which one you are touching.

| | Path | State |
|---|---|---|
| Current app | `index.js`, `lib/` | Plain CommonJS. No TypeScript, no build step, **no tests** |
| Proposal | `docs/proposals/1-draft/001-elixir-multi-tenant-rewrite/` | Ten documents. Nothing generated yet |

**Five of six portals do not crawl.** Immonet no longer exists (sunset into Immowelt),
ImmoScout24 returns 401 behind an AWS WAF challenge, Immowelt and Kleinanzeigen URLs
return 410, wg-gesucht was redesigned. Evidence per portal: `CRAWL-DIAGNOSIS.md` in the
proposal folder. Do not debug a portal without reading it first.

## Facts that change what you do

- **The repo is public.** Nothing machine-local, path-bearing, or vendor-identifying
  gets committed. `.claude/settings.local.json` is gitignored for exactly this reason.
- **There is no Elixir application yet.** Anything in the harness that runs `mix` is
  dormant until `mix igniter.new` has been run. Do not invoke `mix` here.
- **There is no `docs/craft/` rule set and no `docs/adr/`.** Skill references that would
  cite `ARC-001`, `CSS-001`, `WEB-001`, `TST-001` have no ids to cite yet; those
  reference files carry the rules directly instead.
- The proposal board lives at `docs/proposals/`, validated by
  `ruby .agents/bin/check-proposal-board.rb`.
- Harness consistency: `.agents/bin/check-harness.sh`.

## Naming, once the Elixir app exists

Decided in the proposal; use these and nothing else.

| Thing | Name |
|---|---|
| OTP app | `:find_me_a_flat` |
| Core module | `FindMeAFlat` |
| Web module | `FindMeAFlatWeb` |
| Domains | `Accounts`, `Searches`, `Listings`, `Portals`, `Reference` |
| CI gate | `mix ci` |

Domain language is `Subscriber`, `Search`, `SearchPortal`, `Filter`, `Listing`,
`Delivery`, `Portal`, `SelectorSet`, `Provider`. Not "user", not "job", not "scraper".

## Working here

- Read the proposal before proposing architecture; most questions are already answered
  there, with evidence.
- Portal breakage is expected and recurring. Selectors belong in data, not code — that
  is the point of `SelectorSet`.
- Crawl politely. Six third-party sites, real rate limits, active bot detection.
- Never commit `conf/config.json` — it holds a Telegram bot token.

## Agent harness

Skills and agents live in `.claude/`, client-neutral hooks in `.agents/`. See
`.agents/README.md` for the topology and why `.claude/skills` must stay a real
directory rather than a symlink.
