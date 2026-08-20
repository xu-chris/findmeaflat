# Vocabulary

Every term the skills use without explaining. The single answer.

**Paths.** A bare path like `docs/craft/` is **relative to the repository root**, never the skill's own directory. Only markdown links in parentheses resolve relative to their own file.

---

## People and decisions

**Chris** — sole maintainer, the only human in the loop. "Chris decides" means a real human turn, not your judgement.

**`Decided: X by Chris`** — a decision log line that **must quote Chris's actual words**. Without a quote you have no decision: write `Awaiting decision: <the question>` and stop. A `Decided:` line you authored yourself falsifies the record.

**`Decision points: none this round.`** — the honest alternative when nothing needed deciding. Use it only when true; it never replaces asking.

**Stop / wait** (moderated skills) — **end your turn with the question.** Do not write the artifact section depending on the answer, and do not run the next skill this turn. Presenting options and continuing is not stopping.

## Work artifacts

**Proposal card** — one numbered directory holding everything about one piece of work:

```text
docs/proposals/{1-draft,2-shape-go,3-bet-go,4-done}/NNN-problem-slug/
├── CONCEPT.md    every phase
└── PLAN.md       Yellow only; starts in 3-bet-go
```

`capture-idea` creates a card only in `1-draft/` and updates the derived board. `research-and-frame`, `shape`, and `grill-and-bet` record into its `CONCEPT.md`. Promotion moves the same folder: Shape Go `1-draft` → `2-shape-go`, Bet Go `2-shape-go` → `3-bet-go`, verified completion `3-bet-go` → `4-done`. Never create a card in a later lane or copy one between lanes. ADRs stay global in `docs/adr/`; research outliving the feature goes to `docs/research/`, linked from the card.

**`NNN-problem-slug`** — the highest three-digit prefix in any lane plus one, then a lowercase hyphenated problem name: `029-stale-deadline-notifications`, not `029-add-notifications`. Do not fill gaps. Duplicate legacy numbers stay valid; the full numbered slug path is their identity.

**Flat capsule** — a legacy `docs/proposals/<slug>/{frame,shape,bet,plan}.md` directory. Do not create or extend one. Migrate one only through explicit maintainer-approved proposal work.

**`docs/proposals/parked.md`** — one line per parked idea. The only way back: `grill-and-bet`'s tension layer reads it.

## Phases

**OPEN** — the diverging half: generate options, broaden, gather. **CLOSE** — the converging half: synthesise, decide, narrow to an artifact. The product flow is four consecutive OPEN→CLOSE pairs.

**Angles / tastes / defects** — the three divergence mechanisms. See [diverge-converge.md](diverge-converge.md). Only angles get a verify ladder.

**Neutral brief** — the input handed to parallel taste agents: constraints, aims, and evidence, with **no preferred direction and no adjectives that pre-select a winner**. The diverging skill writes it. A leading brief collapses the divergence you paid for.

## Stopping

**Slop zone** — three or four failed attempts on the *same symptom*, counted against the failing test or error, not your latest theory of the cause. The agent has stopped converging; more attempts make it worse. **Stop and hand back to Chris** for manual restructuring. Do not try harder.

**Misjudged complexity** — a task assessed Green revealing itself as Yellow mid-run. The estimate was wrong; the approach is fine. **Stop, record what was learned in `CONCEPT.md`, then route to `plan-work` for `PLAN.md`** while the card stays in `3-bet-go/`. Resume in a fresh context after the plan.

The two look alike from inside; their exits are opposite — a human, or a fresh context.

**Stance** — how a skill treats Chris's turn. **Every skill declares its own stance in its first bold line, and that line is authoritative.** Three values. **Moderated** — stops at decision points and waits. **Autonomous** — runs to the end and reports, though a skill may still name specific mid-run stops. **Co-developed** — moderated only at design boundaries. Read the stance off the skill you are running; this file names no skills, because a roster here goes stale the next time one is added.

## Judgements

**Green / Yellow / Red** — the complexity verdict. See [complexity-assessment.md](complexity-assessment.md). Green fits one context window; Yellow needs a written plan and a fresh context per task; Red cannot be attempted as scoped.

**SLC** — Simple, Lovable, Complete. Ship v1.0 of something narrow, not v0.1 of something broad. Cutting scope **removes jobs the feature does**, never polish, error handling, empty states, or recovery from the jobs that remain.

**Seam** — the public interface another module or a test calls through. Stable means callers do not change when the implementation behind it does. Depth guidance: [../plan-architecture/references/deep-modules.md](../plan-architecture/references/deep-modules.md).

**Bounded context** — one area of the domain with its own consistent language, where a term means exactly one thing. Crawling and notification are separate contexts even when both say "listing": to `Portals` it is parsed HTML, to `Listings` it is a deduplicated record, to `Delivery` it is a message not yet sent.

**Fat-marker level** — concept clear, detail deliberately low, so attention stays on meaning rather than richness. Name mechanisms and their connections, **never** columns, components, copy, or APIs. "The deadline watcher notifies the filmmaker through the existing digest" is fat-marker; naming its template is not.

**Fermi check** — the seven-criterion problem score. Two-minute version in `capture-idea`; the full one-criterion-per-exchange pass in `grill-and-bet`.

**Good Enough** — the bar a shape clears to be bet on: it solves the stated problem for the stated user with no unpatched rabbit hole — not the best version anyone could build.

## Evidence

**Predicate** — one checkable claim, true or false, no scoring between: "SKILL.md is at most 150 lines", "no line matches this regex". A script owns a predicate when running it decides the claim.

**Oracle** — the source that says what the right answer is, fixed *before* the change under judgement: an observed failure, an independently governed rule, an accepted request, or a separate decision from Chris. A source you wrote or weakened inside the same change is no oracle, whatever the edit order.

**Corpus** — the frozen file set, diff, or record list a run is judged against. Every agent in a fan-out gets the identical corpus, or findings cannot be compared.

## Learn hook

The closing beat of every skill; it produces an output **either way**:

> Name one thing that rubbed this run, or write "no friction".
> **Trivial** = a one-line edit to this skill that changes no structure — make it
> now and say you did. Everything **else** is one line in
> `docs/proposals/harness-flywheel.md`.

"No friction" is a claim you are making, not a way to skip the other two.

## Tools named in passing

**Tidewave** — MCP server exposing the running dev server: `project_eval`, `get_docs`, `get_source_location`, `execute_sql_query`, `get_logs`. Needs the server on `localhost:9427`. **Check, do not assume** it is up: if `mcp__tidewave__project_eval` errors, the server is down and `mix compile --warnings-as-errors` is your verification.

**`review-finder` / `review-verifier` / `review-sweep`, `taste-*`, `reader-*`** — subagent definitions in `.claude/agents/` (Claude) and `.codex/agents/` (Codex). Spawn with the host's subagent tool, one per agent, in parallel.

**`ReportFindings`** — a host tool taking `{level, findings}`. When it is not exposed, emit the same structure as one JSON array.

Everything else with an exact name — MCP prefixes, CLIs, labels — is in [docs/agents/research-sources.md](../../../docs/agents/research-sources.md).

**`docs/craft/` and `docs/adr/` are empty.** Skills cite rule ids (`ARC-00n`, `CSS-00n`, `WEB-00n`, `TST-00n`) that have no file behind them yet; [docs/craft/README.md](../../../docs/craft/README.md) maps each citation to where its rule actually lives. **Never reconstruct a rule from its number** — an unresolved citation is an open question, not a constraint you may assume either way.
