# Complexity Assessment

**Replaces appetite everywhere.** Never ask "how much time do we want to spend" — that measures team capacity, and there is no team. Ask:

> **Can an agent do this in one context window at high quality?**

Every compaction degrades output; one that discards failure history makes an agent repeat its mistakes. Context quality is the binding constraint, so it is the unit of estimation.

---

## The verdict

| | **Green** | **Yellow** | **Red** |
| --- | --- | --- | --- |
| Fit | one context window, ≲50% budget including exploration | needs a written plan and a fresh context per task | would compact mid-task, or resists clean decomposition |
| Do | ship in one pass | `plan-work` first; **state the expected number of contexts** | **stop** — cut scope or re-shape |
| Plan file | not required | required | n/a — it never leaves the betting table |

**Red is not "hard", it is "too risky to attempt as scoped."** Reduce scope or re-shape; never try anyway with more effort.

## Estimating the budget

Count what must be *in context at once*, not total lines touched:

- files that must be read to make the change correctly, not just edited
- the tests that prove it, plus their fixtures
- governing rules that apply: routed craft guides, active ADRs, domain docs
- the cost of *finding* those files when their location is unknown

An unknown location is itself a signal: if you cannot name the files, the assessment is Yellow at best until a scouting pass names them.

## Signals that push a verdict upward

- Touches the domain model, or needs / contradicts an ADR → at least Yellow, and routes through `plan-architecture` first
- Data migration, or any irreversible step
- Crosses more than one bounded context
- Needs behaviour established before changing it — in delivery, the failing test and the implementation stay separate commits inside the same unit of work, and characterization against existing behaviour belongs to the dripfeed lane
- The area has no test coverage at all
- Repeated prior failure in this area

## Signals that hold a verdict at Green

- Files are named, few, and already read
- Existing tests cover the behaviour being changed
- Behaviour-preserving, with a stated verification that proves preservation
- One rule, one violation, one fix

---

## Where the verdict is used

| Skill | Use |
| --- | --- |
| `grill-and-bet` | Red never leaves the betting table. Green with no domain-model or ADR impact skips `plan-architecture` and `plan-work` for `build`. Yellow always gets `plan-work`. |
| `plan-work` | Size every task so a **fresh context handles it as Green**. A task that cannot be cut to Green means the plan is wrong, not the task. |
| `diagnose-bug` | The verdict *is* the triage decision: Green earns the `afk` label; Yellow or Red stays for a human. |
| `find-violations` | Only architecture-preserving Green candidates are labelled `afk`. Everything else becomes a ticket with the verdict stated. |
| `build` | A "Green" task revealing itself as Yellow mid-run is a **misjudge**, not the slop zone — stop, record learning in `CONCEPT.md`, run `plan-work` in `3-bet-go`, then resume in a fresh context. |

## Stating a verdict

One line, always with the reason and the count:

```text
Complexity: Yellow — 3 domains. Touches Searches + Listings policies and
the calendar feed token path; needs characterization tests for the feed first
(no coverage today).
```

A verdict without a reason is a guess wearing a colour.
