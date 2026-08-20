# Shaping

How to compare shapes, patch rabbit holes, and write the artifact. `SKILL.md` holds the decision points; this is the method behind them.

## Scope

Ship v1.0 of something narrow, not v0.1 of something broad. Simple is good; incomplete is not.

When the shape is too big, remove a **job the feature does** — a whole use case, actor, or surface. Never remove from the remaining jobs: error handling, empty states, loading states, recovery paths, and the copy that makes them legible.

The test: on the job it keeps, does the narrowed version still hit a rough edge that reads as "unfinished"? If yes, you cut the wrong axis.

## Fat-marker level

Drawn with a marker too thick for detail: named mechanisms and their connections.

| Fat-marker | Too detailed |
| --- | --- |
| "the deadline watcher notifies through the existing digest" | which columns, which HEEx component, which copy |
| "a portal gains a health state searches can filter on" | the enum values and their migration |
| "scraped pages are reviewed before they reach the catalogue" | the review queue's schema and its LiveView |

**A shape that specifies a schema has skipped `plan-architecture` and will be wrong**, because `plan-architecture` decides the domain model with the domain purist in the room.

## Comparing shapes

Compare two or three plausible shapes **when real alternatives exist**. When only one is credible, say why — a finding, not a shortcut.

List at most nine top-level requirements, marked core, must-have, nice-to-have, or out. Include the current system as baseline: doing nothing is always an option, sometimes the right one.

Choose against:

- fit to the frame and the actor it names
- workflow coherence — does the whole job get done, or just the interesting part
- domain ownership and monolith boundaries
- migration and compatibility risk
- operational failure and recovery
- reversibility, and the smallest useful outcome
- maintenance cost for one developer

**Prefer extending the monolith through existing public domain interfaces.** Introduce no service, process, cache, generic abstraction, or new resource without present demand and explicit lifecycle semantics. "We will need it later" is not present demand.

## Rabbit holes

Name everything that could unexpectedly expand the work. The recurring ones:

| Category | What it looks like |
| --- | --- |
| Ownership ambiguity | two contexts could each reasonably own the new concept |
| Data migration | existing rows need a value that did not exist |
| Authorization | a new actor, or an existing record newly reachable by a guest |
| Concurrency | two jobs, or an actor and a job, racing one record |
| Idempotency | a retry or redelivery repeating an effect |
| External effects | email, payment, scraping, an LLM call |
| Compatibility | an existing card, feed, or URL that must keep working |
| Interaction branch | the state nobody drew, usually empty or failed |
| Rollout safety | what a half-deployed version does |

Each gets a **constraint**, a **research result**, or an **explicit exclusion**.

> **"Investigate during implementation" is not a patch.** It converts a known unknown into a surprise, where surprises cost most.

If a material rabbit hole stays open, keep the shape unfinished and name it. That beats betting on a shape with a hole in it.

## The artifact

```markdown
# [Shape]

Evidence summary: [verified state, sources, remaining limits]

## The shape
## Requirements          (core / must-have / nice-to-have / out)
## Considered alternatives
## Rabbit holes and patches
## Won't-do
## Mockups and prototypes  (links)
```

`Won't-do` is load-bearing: it stops the bet from quietly re-growing during `build`. Write the things someone would reasonably assume are included, and say they are not.
