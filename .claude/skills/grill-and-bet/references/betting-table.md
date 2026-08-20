# The Betting Table

Three layers, in this order. The order is the point: scoring first produces an agreeable narrative, tensions first produce commitment.

---

## Layer 1 — Tensions

> "Most of what we call prioritization is forging agreeable narratives. It resolves very little and produces very little real commitment." — Cutler

Read `docs/proposals/parked.md` and the `2-shape-go/` cards first, then ask these out loud. Not rhetorical — each carries a name or it did not work.

| Question | What it catches | Watch for |
| --- | --- | --- |
| What do we keep coming back to without conviction? | survives every review, never ships | usually the real priority or an honest kill |
| Which comfortable work is past diminishing returns while something less fun starves? | the pleasant loop | **the prototyping reflex is the comfortable work here** |
| What has been almost-done forever? | the 90% project | one concentrated push, or kill it. Not a third deferral |
| What keeps boomeranging for "more data"? | decision avoidance dressed as rigour | forces a real `research-and-frame` pass or a kill. **Never a third boomerang** |
| Which modest multiplier work keeps losing because it is unsexy? | time assets | agent labour makes these cheaper than they look |
| What abstract threat do we defer every cycle? | the known existential problem | name it even when the answer is "still deferring" |

## Layer 2 — Should / Can portfolio

A 3×3 adjusted for a solo operator with agents. Vertical = **Should** (how much it matters). Horizontal = **Can** (how feasible).

- **Agents move the Can axis, never the Should axis.** Valuable-but-draining zone-1/2 work shifts right because `find-violations`, `fix-bug`, and `update-dependencies` make it nearly free. This is the biggest change agents make to prioritisation, and it is real.
- **Zone 8 — easy, keeps-us-busy, not valuable — is the top solo failure mode**, and cheap agent labour worsens it. Say the words "this is zone 8" when you see it. Morning triage of overnight PRs shows it first: rubber-stamping busywork means cutting crons, not paying more attention.
- **Zone 3** (valuable and easy) is the go zone. **Zone 9** is bad and needs no discussion.

Place every candidate. A candidate you cannot place is not shaped enough.

## Layer 3 — Decision quality

Skip anything about team coordination or who decides. There is one of us.

1. Does a decision need to be made here?
2. How easily can we reverse it?
3. Can we make this decision smaller?
4. What happens if we don't decide?
5. One-and-done, or repeating?
6. What decisions does this cascade into — does it eliminate decisions or create more?
7. When and how will we know whether it was right?
8. Is action or inaction preferable?
9. What missing information would change the answer? (If the honest answer is "none", stop waiting.)
10. Is the return on effort worth it?

### The walk-away check

Occasionally, always for anything running a while: **visualise shutting it down in concrete detail.** Who gets the email. What gets refunded. What breaks for whom. Then compare that against continuing.

Shipping fast keeps sunk cost low, which makes this check cheap to act on. It antidotes momentum-driven continuation and pairs with the almost-done-forever tension above.

---

## The feature bar

**Demand-pull, not roadmap-push.** Build a feature when prospects refuse to sign up without it, or customers threaten to cancel. Pitchforks, not preferences.

Every feature is permanent, compounding support burden: removing one is harder than never building it. The bar covers features, not maintenance, tooling, or anything reality already forces.

## Good Enough, defined now

Define it **at bet time**, not at ship time. Cutting scope 50% to ship means shipping **100% of what remains**, not a 50% product. That is the mechanism behind SLC, and why "complete" is a marketing decision rather than an engineering state.

Write it under `CONCEPT.md`'s `Decision Made` → `### Bet` as an observable condition, not an adjective.

## Constraints on Go

- **Complexity Red never leaves the table.** Cut scope or re-shape.
- **At most one active bet touching the same bounded context or migration sequence.**
- A park without a concrete trigger is a decline in disguise — say "no" instead.

## Deep Fermi pass

Run the full version of the check `capture-idea` ran in two minutes on a product direction about to become a bet: **one criterion per exchange**, challenge optimism before recording each score, name the evidence class — `[data]` measured, `[research]` sourced, `[fermi]` estimated.

Same seven criteria, same `÷ 625,000`. What changes: the rigour and the requirement to state where each number came from. Deliver the verdict with the weak-link analysis **before** any remedy.
