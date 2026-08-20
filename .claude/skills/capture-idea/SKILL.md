---
name: capture-idea
description: Use when an idea or hunch surfaces and nothing is written down yet. Also use when returning from a prototype, support conversation, interview, or a competitor's release with something worth keeping.
---

# Capture an Idea

**Stance: moderated**, but fast — ten minutes or it failed, and the failure is one line in `docs/proposals/harness-flywheel.md`.

Undefined terms — proposal card, stance, `Decided:` — live in [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` are relative to the repository root, not this file.**

Load nothing else: no craft guides, no ADRs, no source. Reading the codebase here is the failure this skill prevents.

## 1. Two forms

Every idea is either:

- **A problem I have** — business, operational, or personal cost. Say the cost.
- **A problem the user has** — needs an evidence pointer: a message from someone running the bot, a GitHub issue, a portal probe, observed behaviour. See [research sources](../../../docs/agents/research-sources.md).

"A feature I want" is neither. Convert it: *what fails today without it, and for whom?* If it will not convert, that is the finding — carry it to §3 as a Park recommendation. **Parking is Chris's call, not yours.**

One sentence, in domain language, naming the failure. Not the solution.

## 2. Fermi check (optional, ~2 minutes)

Skip it only for ideas that change internal working and nothing else — maintenance, tooling, or a dated external constraint you can name. Unsure? Run it.

All seven criteria in **one exchange**, order-of-magnitude only. One-at-a-time grilling belongs in `grill-and-bet`.

Scales: [references/fermi-check.md](references/fermi-check.md).

Output: **a verdict number and the single weakest link.** Nothing else. No remedies.

## 3. Park or promotion — Chris decides

Present both, then stop. **Write nothing until Chris answers.**

- **Park** → append one line to `docs/proposals/parked.md`: problem statement, evidence pointer or `own cost`, Fermi verdict + weakest link or `no Fermi`, date. Nothing resurfaces it automatically; `grill-and-bet` reads this list when it triages.
- **Promote** → scan every lane, take one past the highest three-digit prefix, create `docs/proposals/1-draft/NNN-slug/CONCEPT.md`: `Evidence summary:` immediately after the H1, then exactly these ordered H2 headings — `Problem Statement`, `Decision Made`, `Consequences & Tradeoffs` — with this capture in the problem section. Add the bullet to `docs/proposals/README.md` under `## 1 — Draft (N)`, raise N, pass `ruby .agents/bin/check-proposal-board.rb`, hand off to `research-and-frame`.

New cards start only in `1-draft/`, never a later lane or a flat capsule. Never move or renumber an existing card here.

## Close

State which happened and the path written. Promote → name `research-and-frame`. Park → say nothing resurfaces it automatically. Log `Decided: park|promote by Chris`, quoting his words; **without a quote write `Awaiting decision: park or promote?` and stop.**

**Learn hook — an output either way.** Name one thing that rubbed, or write "no friction". *Trivial* — a one-line edit to this skill changing no structure — make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
