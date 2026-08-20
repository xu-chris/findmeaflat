---
name: shape
description: Use when a `1-draft` card has a credible frame and the question turns to what to build. Also use for an exploratory spike on that card — a disposable prototype, a dead Phoenix mock page, or hacking at something to test feasibility. A raw spike idea starts with `capture-idea`.
---

# Shape

**Stance: moderated throughout.** A wrong turn here is cheapest to reverse, most expensive to miss. Present options, stop, wait.

Undefined terms and the `Decided:` rule: [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths are relative to the repository root, not to this file.**

**Contract.** In: `docs/proposals/1-draft/NNN-slug/CONCEPT.md`. Out: the selected shape in `Decision Made`, scope bounds in `Consequences & Tradeoffs`, linked mockups. Create no card and no separate shape file. **No `Evidence summary:` there means the card is unframed: stop and route to `research-and-frame`.**

## The sequence

| | Step | Read |
| --- | --- | --- |
| 1 | **Loop back freely** — shaping routinely revises the frame | below |
| 2 | **Diverge** — three design tastes (`taste-minimal`, `taste-bold`, `taste-unexpected`) on a neutral brief | [../\_shared/diverge-converge.md](../_shared/diverge-converge.md) |
| 3 | **Prototype** when a disposable experiment beats discussion | [references/prototyping.md](references/prototyping.md) |
| 4 | **Compare shapes** at fat-marker level | [references/shaping.md](references/shaping.md) |
| 5 | **Wire** only when it clarifies | [references/breadboarding.md](references/breadboarding.md) |
| 6 | **Patch every rabbit hole** | [references/shaping.md](references/shaping.md) |
| 7 | **Write the shape into `CONCEPT.md`** | [references/shaping.md](references/shaping.md) |

Interface behaviour — forms, errors, empty and loading states, navigation, search, confirmation, copy: [references/ux-behavior.md](references/ux-behavior.md).

## 1. Loop back freely

Framing and shaping intertwine. Exploring solutions routinely exposes a narrower actor, a hidden workaround, a different cost, or better domain language.

**Then update `CONCEPT.md`'s Problem Statement and re-check the options against it.** That is the loop working, not scope creep.

## The three rules that decide everything else

**Cut scope, never quality.** Ship v1.0 of something narrow, not v0.1 of something broad. Remove *jobs the feature does*; never the polish, error handling, empty states, or recovery of the jobs that remain.

**Stay at fat-marker level.** Named mechanisms and their connections — never schemas, pixel designs, exact copy, or guessed APIs. **A shape that specifies a schema has skipped `plan-architecture` and will be wrong.**

> **"Investigate during implementation" is not a patch.** Every rabbit hole gets a constraint, a research result, or an explicit exclusion. A material one left open means the shape is not done: say so and stay.

## Prototypes

Start here only with an existing `1-draft` card. Prototypes produce **evidence, not production code**; this skill's close records it in that card.

Phoenix mock pages are cheap — a dead view with maps as data. Reach for one early; a mockup often clarifies the frame faster than more discussion. Then go back to step 1.

## Gate

The shape is done when `CONCEPT.md` records the problem, selected shape, alternatives, rabbit-hole patches, and won't-dos, with no unknown open whose two resolutions would shape it differently.

**`CONCEPT.md` also names the three taste agents that ran and one thing each got right, or states that subagents were unavailable and the pass ran inline.** **Delete every prototype**, or name its repository path, dev-only boundary, and cleanup condition in `Consequences & Tradeoffs`.

**No bet, no Good Enough, no complexity verdict** — `grill-and-bet` owns those.

**Write `Decided: Shape Go by Chris` into `CONCEPT.md` first, quoting his words.** Without that line, do not move the folder. With it, move the whole card from `1-draft/` to `2-shape-go/`, repair incoming links, update `docs/proposals/README.md`, and pass `ruby .agents/bin/check-proposal-board.rb`. Never copy a card or create a later-lane card directly.

## Close

Name the artifact, its path, and the next skill (`grill-and-bet` after Shape Go). Log `Decided: X by Chris` or `Decision points: none this round.`

**Learn hook — output either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill changing no structure: make it now and say you did. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you are making, not a way out of the other two.
