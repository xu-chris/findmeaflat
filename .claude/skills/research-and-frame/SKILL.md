---
name: research-and-frame
description: Use when something already written down needs evidence before any solution thinking — a captured idea, a disputed assumption, or a problem still stated as a feature. Also use when a claim about users or the market needs primary sources, or when a decision was deferred for more data and someone has to go get it.
---

# Research and Frame

**Stance: moderated.** Present findings and stop at every framing decision.

Undefined terms — proposal card, OPEN, angles, stance, `Decided:` — live in [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` are relative to the repository root, not this file.**

OPEN (research) → CLOSE (frame). The output is a written frame, not a conversation.

## Contract

Input: `docs/proposals/1-draft/NNN-slug/CONCEPT.md` from `capture-idea`. Output: its evidence and complete problem framing. A raw idea returns to `capture-idea`; do not create a card here or in a later lane.

Do not choose a solution, design wiring, or open an issue.

## 1. Supplied material

Read everything supplied before asking anything. Extract confirmed facts, provenance, assumptions, gaps. **Do not restart an interview mechanically** — ask only for missing facts, one at a time.

Keep solution ideas already present as explicitly provisional notes. They are not decisions.

## 2. OPEN — research

Assess three evidence angles over a **frozen source set**; [../\_shared/diverge-converge.md](../_shared/diverge-converge.md) has the mechanism. Angles carry a verify ladder: group the candidate claims and mark each `CONFIRMED`, `PLAUSIBLE`, or `REFUTED` before it enters the frame, keeping the first two. Running them inline rather than fanning out keeps the ladder — say so in the output.

| Angle | Hunts |
| --- | --- |
| user-evidence | Own use, messages from people running the bot, GitHub issues, observed behaviour |
| market | competing flat-alert tools, the portals' own alert features, what data vendors (VALUE AG, F+B, bulwiengesa) already sell |
| technical-feasibility | current source, tests, migrations, ADRs, dependency reality |

**There is no user-research corpus for this project** — no Dovetail, no Basecamp, no support inbox. Evidence comes from live portal probes, official open data, the crawl history and the repository, ranked in [research sources](../../../docs/agents/research-sources.md). **A live probe outranks everything, and every probe result carries its date** — portals change weekly, so a three-month-old finding about markup is a hypothesis, not evidence.

**Label every claim** as verified current state, inference, or open question, and cite the exact path or primary source. Old proposals and issues establish provenance — never implementation or feasibility.

**Stop when evidence distinguishes the viable options and bounds material risk.** Not when it is exhaustive.

## 3. CLOSE — frame

Establish these, labelling what evidence does not support rather than forcing closure:

- **Who** — narrower than "everyone". A specific actor or workflow.
- **What they do today** — the actual workaround.
- **What goes wrong** — what fails, stalls, risks, or creates recurring work.
- **Why now** — a specific trigger, not the age of the request.
- **What "solved" looks like** — observable, in domain language.

Use user perspective and observable outcome, never a feature label. "Add notifications" is solution territory. "Programmers miss deadline changes and submit stale schedules" is framable.

Write the evidence summary and Problem Statement section of `CONCEPT.md`:

```markdown
# [Problem-domain title]

Evidence summary: [what is verified, what remains open]

## Problem Statement
### Who is affected
### What they do today
### What goes wrong
### Why now
### What "solved" looks like
### Sources and evidence
### Open questions for shaping

## Decision Made

## Consequences & Tradeoffs
```

Research outliving this one feature goes to a new `docs/research/NNN-research-slug/RESEARCH.md` per `docs/research/AGENTS.md`; the card links to it.

## Gate

Hand to `shape` when the frame is a **credible problem seed**, not a finished theory — `shape` may revise the problem as solutions reveal it. Required: an identifiable actor **and** an evidence source, a stated failure, recorded provenance, at least one cited primary source with a path, URL, or highlight `url`, and no falsely accepted solution. An angle that returned nothing is named as returning nothing.

**Present the candidate framing to Chris and stop.** **Do not write the `Problem Statement` section in the same turn as you propose it.**

If evidence cannot establish a credible problem, say so and stop. Record the missing fact. Do not shape around a weak frame.

## Close

Name the artifact, its path, and the next skill (`shape`). The card stays in `1-draft/`. Log decisions as `Decided: X by Chris`, or state `Decision points: none this round.`

**Learn hook — an output either way.** Name one thing that rubbed, or write "no friction". *Trivial* — a one-line edit to this skill changing no structure — make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
