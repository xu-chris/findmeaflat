---
name: plan-work
description: Use when a bet is Yellow, when work spans more than one context window, or when a task needs decomposing before building. Also use when resuming work whose plan has drifted from reality.
---

# Plan Work

**Stance: moderated.** Chris approves the plan before autonomy begins.

Undefined terms below — proposal card, Green/Yellow/Red, CLOSE, stance, the `Decided:` rule — live in [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` resolve from the repository root, not this file.**

CLOSE. Produces one file that survives across sessions.

## Contract

Input: `docs/proposals/3-bet-go/NNN-slug/CONCEPT.md` after Bet Go. Output: `docs/proposals/3-bet-go/NNN-slug/PLAN.md`.

**Refuse to write PLAN.md unless the card already sits in `3-bet-go/` and its `### Bet` quotes Chris's recorded Bet Go.** Otherwise stop and route to `grill-and-bet`.

Yellow always gets a plan. Green never does — domain-model or ADR impact makes the bet at least Yellow. Red never got here.

**Resuming a drifted plan:** an existing PLAN gets re-sizing and drift repair only. Carry the recorded approval forward; only a changed task set or parent issue needs fresh approval.

## 1. Task size

**The single rule that makes this skill worth running:** each task must be Green for a *fresh* context — see [../\_shared/complexity-assessment.md](../_shared/complexity-assessment.md). **Every task carries its verdict as one line with the reason**; a task without one is unsized, not Green.

A task that cannot be cut to Green means the decomposition is wrong, not that the task is hard. Cut again.

**Budget each slice at roughly 100k tokens of working context** — the range an agent still reasons well in, well under the window it is allowed. Skill and craft reference, the files the slice reads, its test output, and its own diff all draw on that budget. The check is concrete: **a slice that cannot name the files it reads and the one command that verifies it is unsized.** Cut again.

**State the expected number of contexts** at the top of the plan. That number is the estimate; hours are not.

## 2. Red-then-green slices

**No slice may own only tests** — not a baseline slice, not a characterization slice, not a fixture slice. A test-only slice has no implementation holding it honest, so its tests get written by running the code and recording what it already does. That enshrines current behaviour as the expectation and produces tests that pass whatever ships.

Every slice states three steps:

| Step | Contents |
| --- | --- |
| **Red** | the tests, with the **expected failure text**, run on the parent commit — the commit the slice starts from, before any of its changes |
| **Green** | the implementation that makes them pass, **general past the asserted values** — a literal returning the expected answer is a test dump with a stub attached |
| **Verify** | exact command and expected signal |

Tests derive from the accepted `### Bet` and the planned implementation, **never from observed behaviour**. Every test names the requirement it traces to — a line in the accepted `### Bet`, a craft rule id, an active ADR, or a recorded decision.

**A test that passes on the parent commit is a wrong test, not a passing one.**

Shared fixtures land inside the red step of the first slice needing them; later slices extend them. A fixture slice is a test-only slice wearing another name.

Red flags, each one the banned slice: "the fixtures deserve their own slice", "characterization first, then refactor", "this area has no coverage, so establish a baseline". Characterization against existing behaviour belongs to `docs/craft/dripfeed.md` — a different lane, with a different justification.

## 3. Phase matrix

Slices already carry `blocked_by` edges. A **phase** is those edges read out loud: **phase 1 is every slice with no blocker; phase N is every slice whose deepest blocker sits in phase N−1.** A phase is therefore exactly the set of slices that can run at once, and the matrix is *derived* from the edges rather than declared beside them.

**The edges stay the gate.** `build` and any orchestrator take work from the unblocked frontier — a phase number authorises no start. When matrix and edges disagree the edges are right and the matrix is stale. Recompute it.

Every slice appears exactly once.

| Phase | Kind | Slices | Parallel | Blocked by |
| --- | --- | --- | --- | --- |
| 1 | Prefactor | S1, S2 | yes — disjoint files | none |
| 2 | Deliver | S3, S4, S5 | yes | phase 1 |
| 3 | Deliver | S6 | single slice | S4 |

**Name every phase's kind**, because the kind sets what done means for its tickets:

| Kind | Its slices | Green when |
| --- | --- | --- |
| **Prefactor** | Make the change easy before making it; no behaviour change | existing tests pass untouched |
| **Deliver** | A vertical slice, Red → Green → Verify, demoable alone | its own new tests pass |
| **Expand** | Add the new form beside the old | both forms work |
| **Migrate** | One batch of call sites moved across | suite green, old form still standing |
| **Contract** | Delete the old form | suite green, no caller left |

A phase usually holds one kind. A phase mixing kinds must show that no slice in it depends on another, or the mix is hiding an edge.

**Parallel is a claim about files, not about independence in the abstract.** Two slices in one phase writing the same file collide whatever the graph says. Name the files each owns, or split the phase.

**Wide refactors are the one exception to vertical slicing.** A wide refactor is one mechanical change — rename a column, retype a shared symbol — whose blast radius fans across the tree, so a single edit breaks every call site at once and no vertical slice lands green. Sequence it **Expand → Migrate → Contract**: Expand adds the new form beside the old; each Migrate batch is sized by blast radius, blocked by the Expand, and stays green because the old form still stands; Contract deletes the old form, blocked by every batch. When batches cannot stay green alone, keep the sequence, share one integration branch, and add a final **Integrate** phase every batch blocks — then say in the matrix that green is promised there and nowhere earlier.

## 4. Map the files before writing tasks

Which files get created or modified, and what each owns. Decomposition locks in here.

- One clear responsibility per file. Files that change together live together.
- Split by responsibility, not by technical layer.
- Follow established patterns in existing code. Do not unilaterally restructure — though splitting a file you are modifying is reasonable once it has grown unwieldy.

## 5. Write the plan

Read [references/plan-template.md](references/plan-template.md).

Assume the executing agent has **zero context for this codebase**: exact file paths always, the actual code in every step that changes code, exact commands with expected output, TDD order, frequent commits.

**No placeholders.** These are plan failures, not shorthand:

- "TBD", "TODO", "implement later"
- "Add appropriate error handling" / "handle edge cases"
- "Write tests for the above" without the test code
- "Similar to Task N" — repeat it; tasks get read out of order
- References to types or functions no task defines

## 6. Self-review before handing over

Run it yourself, not as a subagent dispatch:

1. **Coverage** — point at the task implementing each accepted requirement in `CONCEPT.md`'s `### Bet`. List gaps.
2. **Placeholder scan** — search for the red flags above.
3. **Consistency** — do names and signatures in later tasks match what earlier tasks defined? `clear_layers/1` in task 3 and `clear_full_layers/1` in task 7 is a bug.
4. **Slice discipline** — every slice carries Red, Green, and Verify; no slice holds only tests or only fixtures; every test names the requirement it traces to. A slice failing this is not a plan you hand over.
5. **Test provenance** — for each test, could you have written that exact assertion without opening the file it targets? A no means the assertion came from the current implementation, not from the requirement. Rewrite it from the requirement or drop it.

6. **Matrix recomputation** — rebuild the phase matrix from the `blocked_by` edges alone, without consulting the one you wrote, then compare. Any difference means the matrix is stale and the edges win. This one is checked by re-deriving, not by asserting.
7. **Slice budget** — every slice names the files it reads and the one command that verifies it. A slice missing either is unsized; cut it.

Fix inline. No second review pass. **Present these seven results with the plan**, one line each, naming what you fixed. A self-review nobody sees is a self-review nobody ran, and §7 hands Chris the plan, not a transcript, unless you put it there.

## 7. Chris approval and issue

Present the completed PLAN plus the epic draft and the slice list, each slice marked AFK or HITL. **Stop here.** `build` starts only after Chris explicitly approves, and **one approval covers the PLAN, the epic, the sub-issue fan-out, and the AFK marking together** — the fan-out is no longer a separate ask. Record the exact approval or waiver in both PLAN and CONCEPT.

Then emit the graph, per [issue-tracker.md](../../../docs/agents/issue-tracker.md): one `epic` parent, one sub-issue per vertical slice, `afk` only where an agent may run the slice unattended. **An unlabelled sub-issue means human in the loop; never read a missing label as permission.** Attach each sub-issue to the epic and record its blockers as native GitHub dependencies, both keyed on the internal issue `id`. Link the card bidirectionally.

**A sub-issue body carries the behaviour its slice delivers and its acceptance criteria, then links the PLAN slice for the rest.** File paths and code go stale on a tracker while `PLAN.md` moves with the code, so paths stay in the plan. The one exception is a snippet pinning a decision more precisely than prose can — a schema, a state machine, a type shape — trimmed to the decision.

## Close

Name the plan path and state `Awaiting decision: approve PLAN, epic, sub-issue fan-out and AFK marking.` Do not name `build` until Chris's approval is recorded. Once he answers, log `Decided: approve PLAN, epic and fan-out by Chris` quoting his words.

**Learn hook — an output either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill that changes no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
