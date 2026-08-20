---
name: plan-architecture
description: Use when a bet touches the domain model, needs a new architectural decision, or contradicts an existing ADR. Also use when domain language is contested, when placing a seam, or when writing or revising an ADR after reality diverged from a decision.
---

# Plan Architecture

**Stance: moderated.** Architecture decisions cost a lot to reverse. Present alternatives, stop, wait.

Undefined terms below — proposal card, Green/Yellow/Red, OPEN, CLOSE, seam, stance, neutral brief, the `Decided:` rule — live in [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` resolve from the repository root, not this file.**

OPEN (alternatives) → CLOSE (a recorded decision; an ADR only after implementation). Fires **only** when a bet touches the domain model or needs / contradicts an ADR. A Green bet with neither skips this skill — see [../\_shared/complexity-assessment.md](../_shared/complexity-assessment.md).

## Contract

Input: a Bet Go card's `docs/proposals/3-bet-go/NNN-slug/CONCEPT.md` before implementation, or a verified delivery from `review-and-ship`; a standalone ADR revision needs no card and outputs the revised `docs/adr/NNN-*.md` alone. Output: architecture decisions in that card's `Decision Made`, plus a new or revised `docs/adr/` record once a qualifying decision is implemented.

## 1. Domain language

Sharpen domain terminology before designing. There is no `docs/domain/` yet; until there is, the domain language is fixed by `AGENTS.md` and the proposal card — **Subscriber, Search, SearchPortal, Filter, Listing, Delivery, Portal, SelectorSet, Provider**. A fuzzy term produces a fuzzy seam; "user", "job" and "scraper" are the fuzzy ones here.

A decision that changes canonical domain language is itself the decision; record it.

## 2. OPEN — three architecture eyes

Neutral brief, three tastes: `taste-domain-purist`, `taste-pragmatist`, `taste-operational`. Mechanism in [../\_shared/diverge-converge.md](../_shared/diverge-converge.md). Converge by synthesis, not by picking a winner.

**Name the three agents you spawned and their distinct positions in the output.** **Without subagents, run the three views inline in one pass and say so.** Labelling positions you wrote yourself as a panel falsifies the record.

## 3. Standing constraints

These bound every option:

- **Extend the monolith through existing public domain interfaces.** No new service, process, cache, generic abstraction, or resource without present demand and explicit lifecycle semantics.
- **Do not pre-build for scale.** Customer patience for transparent growing pains scales with delivered value. Fix scaling under real pressure, never in anticipation.
- **Deep modules over shallow ones.** A seam earns its place by hiding more than it exposes. Read [references/deep-modules.md](references/deep-modules.md) when placing an interface.
- **`docs/craft/` is the desired direction; ADRs are the current decision.** Where they conflict, the ADR wins until deliberately changed — never refactor around an active ADR silently.

## 4. Delivery review

Read [references/slicing.md](references/slicing.md) for the Elixir, Ash, Phoenix and delivery questions a design answers before recording. Vertical slices belong to `plan-work`.

## 5. CLOSE — the decision

**Stop.** Present the synthesis and, when one qualifies, the proposed ADR text. **Write nothing into `docs/adr/` until `Decided: X by Chris` quotes his words.**

Read [references/adr-format.md](references/adr-format.md). An ADR records **implemented, costly-to-reverse tradeoffs**, not intentions. An unimplemented decision belongs in the card's `Decision Made`, never `docs/adr/`.

**Every ADR you write or revise adds an `Applies to:` line** naming the paths it governs — that makes the record searchable, not readable. Most lack one; add it whenever you touch a record. A superseded record carries **`Status:`**; a live one omits it.

**Add a violation signature when the decision is mechanically detectable.** Optional — most ADRs will not have one:

```markdown
## Violation Signature

Query: `rg -n 'String\.to_atom\(' lib/`
Discriminator: only a finding when the argument is externally supplied; a
literal or a compile-time constant is safe.
Known instance (validates the query): none yet — no Elixir source exists. A signature without a known instance is unvalidated; say so rather than trusting its silence.
```

The known instance is not optional when a signature is present. `find-violations` distrusts a query's silence until it has caught something.

## Close

Preimplementation hands to `plan-work`: name the CONCEPT path, note architecture work is Yellow at least. Verified implementation creates or revises qualifying ADRs, names their paths, hands back to completion-only `build`. Log `Decided: X by Chris` quoting his words, or write `Awaiting decision: <question>` and stop. This skill outputs a decision, so `Decision points: none this round.` is never true here.

**Learn hook — an output either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill that changes no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
