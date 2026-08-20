# Craft Rules

**This rule set does not exist yet.** Several skills cite ids — `ARC-001..008`,
`CSS-001..015`, `WEB-001..010`, `TST-001..011` — and name files like
`docs/craft/architecture.md`, `docs/craft/testing.md`, `docs/craft/css.md`,
`docs/craft/phoenix-liveview.md`, `docs/craft/dripfeed.md`, `docs/craft/reviewing.md`.
**None of those files are in this repository.** The citations arrived with a harness
copied from another project.

## What to do when a skill cites an id

1. **Do not invent the rule.** An `ARC-002` you reconstructed from its number is a
   guess wearing an id.
2. **Read the reference file that cites it.** The skill references now carry the rules
   directly:

   | Cited as | Rules actually live in |
   |---|---|
   | `docs/craft/architecture.md`, `ARC-00n` | [`.claude/skills/build/references/backend/architecture.md`](../../.claude/skills/build/references/backend/architecture.md) |
   | `docs/craft/testing.md`, `TST-00n` | [`.claude/skills/build/references/testing.md`](../../.claude/skills/build/references/testing.md) and [`test-examples.md`](../../.claude/skills/build/references/test-examples.md) |
   | `docs/craft/css.md`, `CSS-00n` | [`.claude/skills/build/references/frontend/`](../../.claude/skills/build/references/frontend/) |
   | `docs/craft/phoenix-liveview.md`, `WEB-00n` | [`phoenix-and-frontend.md`](../../.claude/skills/build/references/frontend/phoenix-and-frontend.md) |
   | `docs/craft/dripfeed.md` | nothing — no drip-feed lane is set up |
   | `docs/craft/reviewing.md` | [`.claude/skills/review-and-ship/`](../../.claude/skills/review-and-ship/) |
   | `docs/domain/` | `AGENTS.md` and the proposal card |
   | `docs/adr/` | nothing — no ADR has been written |

3. **Say the citation is unresolved** when it matters to the conclusion. A rule you
   could not read is an open question, not a constraint you may assume away — and not
   one you may assume applies, either.

## Why it is empty rather than filled in

Writing eight architecture rules for an application that does not exist yet would be
inventing constraints from nothing. The rules that *are* real for this project — Ash
over Ecto contexts, selectors as data, Oban OSS with a `PortalGate`, store every listing
permanently, admin-only web surface — are recorded where they were actually decided:
`docs/proposals/1-draft/001-elixir-multi-tenant-rewrite/`.

**Fill this directory once the Elixir application exists and real decisions accumulate.**
At that point, move the rules out of the skill references into numbered files here and
reduce those references back to deltas, which is the shape the harness assumes.

## ADRs

`docs/adr/` is likewise empty. `plan-architecture` writes the first one when a decision
qualifies; its format is in
[`adr-format.md`](../../.claude/skills/plan-architecture/references/adr-format.md).
