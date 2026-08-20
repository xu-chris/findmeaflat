# Production Evidence

**There is no error tracker configured for FindMeAFlat.** No Honeybadger, no Sentry, no
`hb` CLI, no error-tracking MCP server. This harness was adapted from a project that had
one; this project has none. Say so on the issue and diagnose without production evidence
rather than inventing a source.

`docs/proposals/3-bet-go/001-elixir-multi-tenant-rewrite/STACK.md` lists `error_tracker`
and `sentry` as undecided candidates — adopting one is a bet nobody has placed.

## What evidence actually exists today

| Source | Location | Covers |
|---|---|---|
| Winston logs | `logs/app.log`, `logs/error.log`, `logs/scraping.log` | The Node crawler. Rotated at 5 MB × 5 (10 MB × 3 for scraping) |
| Console output | stdout of the container | Raised to `warn` when `NODE_ENV=production` |
| GitHub Actions | `gh run list`, `gh run view <id> --log-failed` | CI failures only |
| A live portal probe | `curl` — see [../../../../docs/agents/research-sources.md](../../../../docs/agents/research-sources.md) | What the portal returns *right now* |

**The logs are the weak link, and knowing why matters for diagnosis.** The current
system cannot distinguish "no new flats" from "the portal returned 410 Gone" — both
appear as `Found 0 new listings`. A quiet log is not evidence that crawling worked. When
a report says "the bot stopped finding flats", the log will not tell you which portal
broke; a probe will.

## Once the Elixir app exists

`PortalHealth` and `SearchPortal.consecutive_empty_runs` become the primary production
evidence: per-portal HTTP status distribution, cards parsed per run, challenge-detected
counts, and a `:broken` state that fires a Telegram warning. That is designed precisely
so this section stops being short.

Until then, prefer reproducing locally over inferring from logs.
