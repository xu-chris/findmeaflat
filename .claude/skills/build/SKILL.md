---
name: build
description: Use when a Bet Go card has an approved Yellow PLAN or an accepted Green bet ready to implement, for a completion-only card move after review, or when a card's implementation touches Elixir, Ash, Phoenix, LiveView, HEEx, CSS, motion, or tests.
---

# Build

**Stance: autonomous.** Chris sees results, not steps. Three stops interrupt — §5. A spawned slice can return two more, routed in §3.

Undefined terms — proposal card, Green/Yellow/Red, seam, stance, the `Decided:` rule: [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` start at the repository root, not this file.**

One skill, no backend/frontend split: a LiveView feature touches an Ash resource, a HEEx component, and a stylesheet at once.

## Entry gate

Build starts only from `docs/proposals/3-bet-go/NNN-slug/CONCEPT.md` with its accepted `### Bet`. **Read the Green/Yellow verdict recorded there at Bet Go; never re-derive it.** No verdict, no entry — route to `grill-and-bet`. **Yellow also needs Chris's recorded PLAN approval plus the epic URL or a recorded waiver**; Green needs the recorded Bet Go decision. Route a raw request, a `1-draft` or `2-shape-go` card, or an unapproved PLAN to `capture-idea`, `grill-and-bet`, or `plan-work`; never implement it here.

## 1. Reference load

Read a row's file only when its condition holds.

**Backend**

| Touching | Read |
| --- | --- |
| Elixir, Ash, Spark, Boundary, ReqLLM, telemetry, DSL | [references/backend/elixir-and-ash.md](references/backend/elixir-and-ash.md) |
| LLM prompts, tool schemas, model responses | [references/backend/llm-prompts-and-tools.md](references/backend/llm-prompts-and-tools.md) |
| Module boundaries, contexts, seams | [references/backend/architecture.md](references/backend/architecture.md) |
| A reusable generator or AST refactor as a Mix task | [references/backend/igniter.md](references/backend/igniter.md) |
| Any dependency's own rules (Ash, Phoenix, Igniter, ReqLLM…) | [references/backend/dependencies.md](references/backend/dependencies.md) — generated index, links into `deps/` |

**Frontend.** Each entry links deeper files; load the parent and follow.

| Touching | Read |
| --- | --- |
| Phoenix, LiveView, HEEx, components | [references/frontend/phoenix-and-frontend.md](references/frontend/phoenix-and-frontend.md) |
| Visual detail, layout, copy — through it accessibility, colour, typography | [references/frontend/interface.md](references/frontend/interface.md) |
| Animation, transitions — through it naming an effect | [references/frontend/motion.md](references/frontend/motion.md) |

**Always**

| | |
| --- | --- |
| Every change | [references/testing.md](references/testing.md) |
| Hard rules | `CODING_STANDARDS.md` |
| Desired direction, routed by changed files | `docs/craft/` — `README.md`, then only the routed leaves |
| Current decisions | `docs/adr/` for the areas you touch |

Existing code is **evidence, never target architecture**, however frequent the pattern. Agents echo patterns; a bad one spreads at agent speed.

## 2. Test order

Red → green → refactor, at a stable public seam. The test proves the behaviour the plan asked for and fails for the right reason first.

**Commit red before green.** The failing test and its expected failure text land in one commit; the implementation lands in the next. A single diff that writes the proof and changes the code proves nothing.

**Never give a slice only tests.** Delivery work has no characterization pass, no baseline slice, no fixture slice — tests derive from the slice in PLAN and the accepted `### Bet`, never from running the code to see what it does. A test passing before the implementation commit is wrong, not done. **Run the area's existing tests and paste the result before claiming no coverage**, then write the missing tests inside the slice that needs them. Characterization against existing behaviour belongs to `docs/craft/dripfeed.md`.

**The slice touches uncovered legacy code with no requirement to trace to.** Write only the tests your slice's own behaviour needs, then append one row to `docs/craft/dripfeed.md` under `### Ready`, in its four columns — candidate, rule, evidence, design cost today — meeting that file's Candidate Contract. Write `No rule yet` when no craft rule fits. **The row is a candidate for Chris: it authorises nothing and starts no lane.** Keep the slice moving, and leave the uncovered area uncovered rather than characterizing it inline.

## 3. Plan execution

Start from `docs/proposals/3-bet-go/NNN-slug/CONCEPT.md`. A Green bet carries no PLAN: follow the accepted `### Bet` and implement it here. A Yellow PLAN carries slices, and every slice goes to a `slice-implementer`. Tick steps off in PLAN — the plan is state, not a transcript.

**Take work from the unblocked frontier, never from a phase number.** PLAN records which slices block which, one edge per dependency; the frontier is every slice whose edges all point at landed work. A slice has landed once its verify command has run and passed — a green commit alone does not land it. Those edges derive PLAN's phase matrix, which goes stale; the edges win when they disagree.

`.agents/bin/slice-frontier.sh <epic-number>` walks those edges for you and prints the wave. It separates a slice that is ready for an agent from one that is merely unblocked — an unblocked slice without `afk` is ready for Chris. It reads GitHub only: no branch is cut and no agent is spawned by running it.

**It reads issue state, so keep issue state current.** A slice counts as landed when its sub-issue is closed, and that close follows its merged pull request. A slice whose pull request merged but whose issue is still open holds the whole next wave.

**Spawn one `slice-implementer` per ready slice, handing over every row below.** It stops on a missing input rather than reconstructing the slice from its title, so a row you skip costs a round trip instead of a wrong slice.

| Hand over | Source |
| --- | --- |
| Red, Green, Verify, Reads | the PLAN slice |
| Slice id | the PLAN slice |
| Parent commit it starts from | your frontier scan |
| Feature branch its pull request targets | the card's feature branch |
| Sub-issue body, or the word `none` | the epic's sub-issue for this slice |
| Worktree to work in | one per slice when dispatching in parallel |

**Hand over the sub-issue body, or say `none`.** The subagent stops when PLAN and its sub-issue disagree, and that check cannot fire on an artifact it never received. Silence there reads as agreement and ships the wrong behaviour.

**One feature branch per card; every slice branches off it and returns by pull request.** The card's feature branch carries `PLAN.md` and is where the bet is assembled. Each slice gets its own branch cut from it, in its own worktree. The subagent pushes that branch and opens one pull request into the feature branch — never into `main`, and it merges nothing. Chris reviews and merges, so the feature branch grows a reviewed slice at a time and stays testable end to end. One last pull request takes the whole feature branch to `main`.

**That review gate is what makes waves real.** A slice cut before its blocker merged branches from a feature branch that does not contain the blocker. Dispatch a wave, wait for those pull requests to land, then cut the next wave from the updated feature branch — do not open the whole matrix at once.

**Parallel dispatch needs disjoint files and a free branch.** The phase names the files. The branch nobody names: `slice-implementer` commits to the current branch, so two of them committing at once race the same index, however disjoint their files. Give each parallel slice its own worktree, or collect the reports one at a time.

**Act on a returned stop signal yourself; never retry it.** Re-dispatching the same slice to a fresh agent thrashes with extra steps.

**One report can carry two signals, and their exits are opposite. The human exit wins.** A slice that spent its budget on four failed attempts is both a sizing failure and a slop zone: one says the slice was too big, the other says nobody has understood the symptom yet. Re-cutting a symptom nobody understands hands the same wall to two smaller agents, so route it to Chris and leave the re-cut until after he answers.

| Returned signal | Route |
| --- | --- |
| Slop zone | §5 — hand back to Chris |
| Misjudged complexity | §5 — `plan-work`, fresh context |
| Sizing failure: budget spent, slice unfinished | `plan-work` to cut the slice smaller. Never re-run it whole |
| PLAN contradicts the sub-issue | Stop. Put both to Chris — guessing which one is current silently rewrites the bet |
| Code backed out as not understood | §5 — the slice is unfinished, however clean the branch looks |

**One concern per commit.** Feature or refactor, never both.

**Verify each change before the next; never batch.** This governs what you implement yourself and each report you accept, never the size of the fan-out — parallel slices each verify inside their own run. Dev server live → Tidewave runtime checks. Server stopped → `mix compile --warnings-as-errors`. **Check which, do not assume** — `mcp__tidewave__project_eval` erroring means the server is down. A server answering is not a server serving this checkout: a slice returning a runtime signal from another checkout has verified code you did not change.

## 4. Out-of-scope findings

Broken but out of scope? Log it as a `find-violations` candidate or a bug issue. Never fix it inline. Unrelated drift is not feature-PR scope.

## 5. Stops

| | **Slop zone** | **Misjudged complexity** |
| --- | --- | --- |
| Signal | 3–4 failed attempts on the *same symptom*, counted against the failing test or error, not your latest theory | a "Green" task revealing itself as Yellow |
| Meaning | the agent is now a liability here | the estimate was wrong, the approach is fine |
| Do | **stop. Hand back to Chris** for manual restructuring. No thrashing, no trying harder. | **stop.** Record what you learned in CONCEPT, route to `plan-work` for PLAN, card stays in `3-bet-go/`. Resume in a **fresh context**. |

**The third stop, outside the table: never ship code you do not understand.** Back it out.

## Close

Execution complete: card stays in `3-bet-go/`. Report what changed, what verified it, what you logged unfixed, and the next skill (`review-and-ship`). Log `Decided: X by Chris` only when quoting Chris. A decision owed and unanswered: write `Awaiting decision: <question>` and stop. None arose: write `Decision points: none this round.`

Run `build` again only for completion, after `review-and-ship` reports no retained finding and no `unverified` angle. First open `docs/proposals/AGENTS.md` § Complete a Card and quote each requirement beside its evidence — a requirement ticked from memory is not checked. A qualifying ADR routes through `plan-architecture` first. Then move the same folder to `4-done/`, repair links, update the board, and pass `ruby .agents/bin/check-proposal-board.rb`. **Incomplete work stays in `3-bet-go/`; never copy the card.**

**Learn hook — it outputs either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill changing no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not an escape from the other two.
