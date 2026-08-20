---
name: grill-and-bet
description: Use when a shape is ready for a go/no-go, when deciding what to work on next, or when triaging what has piled up. Also use when something has been almost-done forever, or to stress-test a plan or decision before committing.
---

# Grill and Bet

**Stance: moderated.** The agent prepares evidence and recommends. Chris decides. **Without an explicit decision from Chris, nothing moves and no artifact is created.**

Undefined terms — proposal card, Green/Yellow/Red, CLOSE, Good Enough, bounded context, stance, the `Decided:` rule: [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` are relative to the repository root, not to this file.**

CLOSE. Two entry modes.

| Mode | Trigger | Path |
| --- | --- | --- |
| **Portfolio** | "what next", a shape ready to bet, periodic review | §1 → §2 → §3 → §4 |
| **Grill only** | "stress-test this", "grill me on X" | §2 alone, on any target |

## 1. Tension surfacing

**Read `docs/proposals/BETTING_TABLE.md` first — Capacity, then Candidates. No Go while free slots are zero.** An empty lane or parked list is a finding: say so and run §2 on the named target.

Scoring first produces an agreeable narrative; tensions first produce commitment. Read `docs/proposals/parked.md` and the `2-shape-go` cards, then ask:

- **What do we keep coming back to without conviction?**
- **Which comfortable work is past diminishing returns while something less fun starves?** *(watch the prototyping reflex — the comfortable work here)*
- **What has been almost-done forever and needs one concentrated push or an honest kill?**
- **What keeps boomeranging for "more data"?** That forces a real `research-and-frame` pass or a kill. Never a third boomerang.
- **Which modest multiplier work keeps losing because it is unsexy?**

The full three-layer procedure: [references/betting-table.md](references/betting-table.md).

## 2. Grill the shape

Attack it with `docs/` as ammunition — ADRs, craft guides, domain docs, prior research. Relentless, specific, one line of attack at a time. The target defends or the shape changes.

Run the **deep Fermi pass** on a product direction about to become a bet: one criterion per exchange, challenge optimism before each score, name the evidence class. `capture-idea` ran the 2-minute filter; this is the workshop version.

## 3. Portfolio check — Should / Can

Cutler's 3×3, agent-adjusted. Vertical = Should (how much it matters), horizontal = Can (how feasible).

- **Agents move the Can axis, not the Should axis.** Valuable-but-draining zone 1/2 work shifts right: `find-violations` and the overnight lanes make it cheap.
- **Zone 8 — easy, keeps-us-busy, not valuable — is the top solo failure mode**, and agents worsen it. Name it out loud when you see it.
- Zone 3 (valuable and easy) is the go zone. Zone 9 is bad.

## 4. Verdict

Assess complexity per [../\_shared/complexity-assessment.md](../_shared/complexity-assessment.md). **Red never leaves the table** — cut scope or re-shape.

Check the feature bar: **demand-pull, not roadmap-push.** Build when prospects refuse to sign up without it or customers threaten to cancel. Every feature is permanent, compounding support burden.

Define **Good Enough now**, at bet time. Cutting scope 50% means shipping 100% of what remains, not a 50% product.

Run the solo-relevant decision questions and the **walk-away check** — visualise shutting it down in detail, who to email, what to refund — from `references/betting-table.md`.

### Verdicts

| Verdict | Action |
| --- | --- |
| **Go** | **Only after Chris's recorded Bet Go, quoted verbatim:** record what we bet on, Good Enough, the complexity verdict as one line with its reason and expected context count, and explicit exclusions under `CONCEPT.md`'s `Decision Made` → `### Bet`. Then move the same card from `docs/proposals/2-shape-go/` to `docs/proposals/3-bet-go/`, repair links, update the board and `docs/proposals/BETTING_TABLE.md`, and pass `ruby .agents/bin/check-proposal-board.rb`. Route by the first matching row: domain-model or ADR impact → `plan-architecture`, then `plan-work`; Yellow → `plan-work`; Green with neither → `build`. |
| **Park** | On Chris's recorded Park: write its trigger under `CONCEPT.md`'s `Consequences & Tradeoffs` → `### Parked`, then one line into `docs/proposals/parked.md`. Leave the card in `docs/proposals/2-shape-go/` and drop it from active candidates. **A park without a concrete trigger is a decline disguised as backlog** — say "no" instead. |
| **Return** | The shape has a gap; nothing to bet on yet. On Chris's recorded decision, write the gap into `CONCEPT.md`, move the card back from `docs/proposals/2-shape-go/` to `docs/proposals/1-draft/`, update the board, and pass the checker. Next skill: `shape`. |
| **Already built** | Completion audit: verify against source, tests, and migrations. Do not re-bet on shipped work. **Do not move it** — record the audit in `CONCEPT.md`. Only `build`'s completion run moves a card, and only from `3-bet-go/`. |
| **Kill** | On Chris's recorded Kill: say so plainly and record why under `CONCEPT.md`'s `Consequences & Tradeoffs` → `### Won't-do`. Leave the card in `docs/proposals/2-shape-go/` and drop it from active candidates. A killed bet is a decision worth finding later, not a deleted card. |

**At most one active bet touching the same bounded context or migration sequence.**

## Not-doing is decided here, one proposal at a time

No roadmap, no annual not-do list. **Every not-do is scoped to the proposal that raised it**, and lands in one of three places:

| Decision | Where it lives |
| --- | --- |
| Out of *this* shape, but the shape ships | `CONCEPT.md` → `Consequences & Tradeoffs` → `Won't-do` |
| Not now, with a concrete trigger | `docs/proposals/parked.md` |
| Not at all | `CONCEPT.md` → `Consequences & Tradeoffs` → `Won't-do`, with the reason |

Write the things someone would reasonably assume are included and say they are not. That list stops a bet re-growing during `build`, and is the only durable record that a choice was made rather than overlooked.

Go needs Chris's actual recorded decision. Without it, leave the card in `2-shape-go/`; never create or copy a card into `3-bet-go/` yourself.

## Close

Name the card path, the `CONCEPT.md` section written, and the next skill. State every verdict with its reason and its opportunity cost. Log `Decided: X by Chris` quoting his words — **never log a decision you answered yourself**. Without a quote, write `Awaiting decision: <question>` and stop. `Decision points: none this round.` when none arose.

**Learn hook — output either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill changing no structure: make it now and say you did. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you are making, not a way out of the other two.
