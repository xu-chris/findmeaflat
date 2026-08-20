# Proposal Board

Cards move left to right through four lanes. A card is a directory `NNN-slug/`
containing `CONCEPT.md` with exactly three H2 sections — `Problem Statement`,
`Decision Made`, `Consequences & Tradeoffs` — plus any supporting documents.

`PLAN.md` appears only after Bet Go, in `3-bet-go/`.

Validate with:

```sh
ruby .agents/bin/check-proposal-board.rb
```

## 1 — Draft (0)

## 2 — Shape Go (0)

## 3 — Bet Go (1)

- [001 — Elixir Multi-Tenant Rewrite](3-bet-go/001-elixir-multi-tenant-rewrite/CONCEPT.md) — replace the single-user Node crawler with one multi-tenant Elixir/Phoenix/Ash deployment; fix four crawlable portals; Telegram for users, authenticated Phoenix admin. Bet Go recorded; Phase 1 only, enrichment excluded.

## 4 — Done (0)
