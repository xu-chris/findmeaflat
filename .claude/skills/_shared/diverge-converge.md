# Diverge / Converge

The shared pattern behind every OPEN and CLOSE. Skills point here and name their own set; nothing below is copied into a skill.

**Why it works:** starting points shape outcomes. One agent asked for three options gives three variations on one idea; three agents with different biases give three ideas.

**Cost guard: 3 agents by default.** More needs a stated reason in the skill's output. Each agent is read-only and cannot delegate.

---

## Three mechanisms — pick by what varies

| | **Angles** | **Tastes** | **Defects** |
| --- | --- | --- | --- |
| What varies | the hunting lens | the bias | the reader |
| Input | one frozen artifact | one neutral brief | one document |
| Output | candidate claims | candidate options | candidate failures |
| Needs a verify ladder? | **yes** | no | no |
| Used by | `review-and-ship`, `find-violations` | `shape`, `plan-architecture`, `fix-bug` | `craft-skills`, `craft-agents-md` |

A verify ladder over *options* refutes them for being options. Skipping one over *claims* ships guesses.

---

## Angles — divergent finding over a fixed artifact

1. **Freeze the artifact first.** Resolve the exact diff, file set, or corpus, record the commands, and give every agent the identical packet. Unfrozen, agents review different things and results cannot be compared.
2. **One angle per agent**, plus a candidate cap. An agent receives only its angle, the packet, governing sources, and what it must not do.
3. **Verify.** Group candidates by `(file, line)` before dispatch — finders collide roughly 40% of the time, and grouping cuts verifier count by about that much. Each group returns exactly `CONFIRMED`, `PLAUSIBLE`, or `REFUTED`. Keep the first two, drop the third.
- **`PLAUSIBLE` is the default.** Do not refute for being "speculative" or "depends on runtime state" when the state is realistic: concurrency races, nil on a rare-but-reachable path, falsy-zero, off-by-one on a boundary the code does not exclude, retry storms, an allowlist that lost its anchor.
- **`REFUTED` only when constructible from the artifact:** factually wrong (quote the line), provably impossible (type, constant, invariant), already handled here (cite the guard), or pure style with no observable effect.
4. **Sweep at high fan-out only.** One fresh agent sees the verified list and hunts *gaps*. An empty sweep is correct; never pad it.
5. **A failed or unavailable agent is `unverified`, never a clean angle.**

## Tastes — divergent generation from one brief

1. **Write the brief neutrally.** Constraints, aims, and evidence — no preferred direction, no adjectives that pre-select a winner. A leading brief collapses the divergence you paid for.
2. **Run the taste agents in parallel.** Each is defined in `.claude/agents/` with its bias in the prompt, not in the call.
3. **Converge by synthesis, not selection.** Name what each option gets right, then compose the parts that work together. Picking a winner and discarding the rest wastes two thirds of the run.
4. **Present the synthesis to Chris with the trade-offs.** Moderated skills stop here.

## Defects — divergent reading of a document

For any document whose consumer is an agent. Each defect surfaces a failure the others structurally cannot see.

| Reader | Reads as | Surfaces |
| --- | --- | --- |
| **Literalist** | zero background knowledge, executes exactly what is written | undefined terms, missing context, unstated prerequisites |
| **Skimmer** | extracts an action plan from headings and bold text | buried constraints — whatever it drops must move up or be bolded |
| **Rationalizer** | complies with the letter against the spirit | unenforced gates — close them with an acceptance test or an explicit consent rule |
| **Process-reflector** | narrates the workflow the document implies | missing connective tissue between steps (workflow documents only) |
| **Editor** | reads for prose, not content | buried actions, padding, banned sentence forms; hands back the rewrite |

**Patch against their lists, then re-run if the patches were structural.** Cheap pressure-testing: no baseline run needed.

---

## Converge — every CLOSE

A CLOSE is not a summary. It ends in an artifact and a named decision.

- **Write it down.** Writing solidifies, chat dissolves. The artifact lands in `/docs`, on the issue, or on the PR — attached to the thing it concerns.
- **Log decisions explicitly:** `Decided: X by Chris`. Never log a decision you answered yourself. When none arose, say `Decision points: none this round.` Silence must not masquerade as consent.
- **Hand off by naming the artifact, its path, and the natural next skill.** Nothing auto-chains.
- **Close with the learn hook** (≤30 seconds): *did this run reveal friction — a gap in guidance, an arbitrary decision, wasted effort? If trivial, fix the skill now; otherwise one line into `docs/proposals/harness-flywheel.md`.*

## Agent lineup

Defined in `.claude/agents/` (Claude) and `.codex/agents/` (Codex mirrors of the roles Codex runs).

| Set | Agents |
| --- | --- |
| Design tastes | `taste-minimal` `taste-bold` `taste-unexpected` |
| Architecture tastes | `taste-domain-purist` `taste-pragmatist` `taste-operational` |
| Bug-fix tastes | `taste-simple-fix` `taste-thorough-fix` `taste-creative-fix` |
| Defective readers | `reader-literalist` `reader-skimmer` `reader-rationalizer` `reader-process-reflector` `reader-editor` |
| Review roles | `review-finder` `review-verifier` `review-sweep` |

**Degradation:** when subagents are unavailable, run the angles or tastes inline in one pass and **state that in the output**. Never present a single-pass run as full fan-out.
