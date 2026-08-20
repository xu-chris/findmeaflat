# Research Sources

Exact names — MCP prefixes, CLIs, endpoints — for the evidence sources available to this
project.

**FindMeAFlat has no user-research corpus.** This harness was adapted from a project that
assumed a research tool (interview highlights) and a product-records tool. Neither is
configured here. Evidence for this project comes from the portals themselves, official
open data, the crawl history, and the repository.

## Evidence hierarchy

| Rank | Source | Establishes |
|---|---|---|
| 1 | **A live probe** — `curl` against the actual portal | What is true *today*. Portals change weekly; nothing outranks a fresh probe |
| 2 | **Official open data** — see below | Legal and statistical ground truth |
| 3 | **The repository** — source, git history, issues | What we built and why |
| 4 | **The proposal documents** | Prior verified findings, with dates attached |
| 5 | Web search, vendor docs, forums | Orientation only. Never feasibility |

**Every probe result carries its date.** A finding from three months ago about a portal's
markup is a hypothesis, not evidence.

## Portals

The six the crawler targets. Probe with the current config `User-Agent`; record status,
size, and which selectors matched.

| Slug | Host | Status as of 2026-08-20 |
|---|---|---|
| `immowelt` | `www.immowelt.de` | 200, SSR HTML, selectors valid, URLs changed |
| `kleinanzeigen` | `www.kleinanzeigen.de` | 200, all selectors valid (domain renamed from `ebay-kleinanzeigen.de`) |
| `immosuchmaschine` | `www.immosuchmaschine.de` | 200, one dead attribute |
| `wg_gesucht` | `www.wg-gesucht.de` | 200, redesigned |
| `immoscout` | `www.immobilienscout24.de` | **401**, AWS WAF challenge |
| `immonet` | — | **Sunset into Immowelt.** Portal no longer exists |

Full per-portal evidence:
`docs/proposals/1-draft/001-elixir-multi-tenant-rewrite/CRAWL-DIAGNOSIS.md`.

## Open data

| Source | Endpoint | Licence |
|---|---|---|
| Berlin Wohnlagen (Mietspiegel) | `https://gdi.berlin.de/services/wfs/wohnlagenadr2026` | `dl-de/zero-2.0` |
| Berlin Gebäudealter (Umweltatlas) | `daten.berlin.de`, WFS | `dl-de/zero-2.0` |
| Dortmund Mietspiegel | `https://open-data.dortmund.de/api/explore/v2.1/catalog/datasets/fb64-mietspiegel-2025-2026/records` | open |
| GovData (national catalogue) | `https://www.govdata.de/ckan/api/3/action/package_search?q=Mietspiegel` | varies |
| OpenStreetMap | `https://overpass-api.de/api/interpreter` | ODbL |

**A 200 is not a success.** Berlin's GDI returns HTTP 200 with a 1411-byte
*Wartungsarbeiten* page during maintenance. Validate shape, never status. Full
assessment: `OPEN-DATA.md` in the proposal folder.

## Package and version facts

- **Hex:** `https://hex.pm/api/packages/<name>` — `releases[0]` includes pre-releases,
  so filter for the latest *stable* before quoting a version.
- **npm:** `https://registry.npmjs.org/<name>` — `time.modified` reveals abandonment.
- **hexdocs:** `https://hexdocs.pm/<pkg>` redirects to `https://<pkg>.hexdocs.pm/`;
  fetch the redirect target.

## CLIs

| Tool | Use |
|---|---|
| `gh` | Issues, PRs, labels, sub-issues — see [issue-tracker.md](issue-tracker.md) |
| `git` | History is evidence; `git log -S` finds when a selector changed |
| `curl` | Portal and open-data probes |
| `ruby .agents/bin/check-proposal-board.rb` | Proposal board validity |
| `.agents/bin/check-harness.sh` | Skill harness validity |

**Not available here:** `basecamp`, `hb` (Honeybadger), `mix` (no Elixir app yet),
`wt` only if worktrunk is installed locally.

## MCP

`tidewave` is configured in `.claude/settings.json` but has **nothing to attach to**
until the Elixir application exists. Its tools will fail until then; that is expected,
not a fault to debug.

No research-tool connector is configured for this project. A skill instructing such a
call is leftover from the harness this was adapted from — treat the instruction as
absent and say so.
