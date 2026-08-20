# Proposal PLAN Template

One `PLAN.md`, only in its Bet Go card:
`docs/proposals/3-bet-go/NNN-slug/PLAN.md`.

```markdown
# [Proposal] Implementation Plan

> **For agents:** Use `build`; stop when PLAN and CONCEPT conflict.

**Outcome:** [one sentence]
**Epic:** [URL or dated explicit maintainer waiver]
**Sub-issues:** [one per slice: URL, slice id, AFK or HITL, blocked-by]
**Owner/complexity:** [from accepted bet]
**Architecture:** [two or three sentences]
**Relevant stack:** [only touched technologies]

## Decisions and Evidence
[Verified current state, desired direction, inferences, resolved unknowns]

## Boundaries and Non-goals

## Existing System Context
[Exact paths/public seams; reusable capability; constraints]

## Vertical Slices

### S1 — [Demoable outcome]
**Acceptance:** ...
**Red:** the tests, each naming the requirement it traces to, with the expected failure text on the parent commit
**Green:** the implementation that turns them
**Verify:** exact command; expected signal
**Reads:** the files this slice opens — the sizing evidence, not a wish list
**Uncertainty:** ...
**Depends on:** none, or the slice ids that block it
**Likely boundaries:** ...
**Excludes:** ...

No slice holds only tests. Fixtures land in the red step of the first slice needing them.

## Phase Matrix
Derived from the `Depends on` edges, never declared beside them: phase 1 is every slice with no blocker; phase N is every slice whose deepest blocker sits in phase N−1. Every slice appears exactly once. Mermaid only when branching or three-plus dependencies earn it.

| Phase | Kind | Slices | Parallel | Blocked by | Mode |
| --- | --- | --- | --- | --- | --- |
| 1 | Prefactor | S1, S2 | yes — disjoint files | none | AFK, AFK |
| 2 | Deliver | S3, S4 | yes | phase 1 | AFK, HITL |

Kind is one of Prefactor, Deliver, Expand, Migrate, Contract, Integrate. Mode is AFK or HITL per slice; only AFK becomes a label, HITL is the absence of one. `Parallel` is a claim about file ownership — name the files each slice owns or split the phase.

## Architecture and Delivery Review
[Relevant answers from architecture reference]

## Implementation Tasks

### T1 — [Outcome]
**Slice:** S1
**Files:** Create/Modify/Test exact verified paths
**Behavior/invariant:** ...
**Steps:** ...
**Verify:** exact command; expected signal
**Depends on:** none
**Parallel safety:** no, or reason yes
**Docs:** moduledoc/doc/domain/ADR follow-up

## Verification Matrix
| Concern | Public seam | Check | Expected signal |
| --- | --- | --- | --- |

## Rollout, Observability, and Rollback

## Execution Frontier
[Detailed unblocked tasks; collision notes]

## Completion Handoff
[Final checks, code docs, ADR/reflection, issue close, move to done]
```

Keep PLAN operational; update checkboxes and evidence during implementation. Architecture truth lives in current code documentation and implemented ADRs; the product decision stays in CONCEPT.
