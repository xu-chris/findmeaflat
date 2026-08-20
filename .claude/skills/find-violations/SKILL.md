---
name: find-violations
description: Use when scanning the codebase for anything wrong with it — craft-rule or ADR violations, every place a rule is broken, or architectural friction and missing test seams that no numbered rule names. The only scanning skill; it finds and tickets, never repairs. Mode A runs unattended nightly; Mode B runs on demand.
---

# Find Violations

**Stance: autonomous.** Find and ticket. Repairs belong to `fix-violation`.

Undefined terms: [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths are relative to the repository root, not this file.**

**Mode A is headless.** Nightly cron, `.github/workflows/harness-find-violations.yml`. Runners: Claude cloud or Codex cloud. Expected 7 runs/week. **Mode B never runs on that cron** — see Modes below.

**Angles, so the verify ladder applies** — [../\_shared/diverge-converge.md](../_shared/diverge-converge.md). Freeze the corpus and record the commands that built it. Give every agent the identical packet and one signature each. Group candidates by `(file, line)`, return `CONFIRMED`, `PLAUSIBLE`, or `REFUTED` per group, keep the first two. One signature per agent may push a run past that file's default of three agents; say how many ran and why.

Check for an open signature pull request before opening another: `gh pr list --search 'docs: add violation signatures in:title' --state open`. Push to that branch when one exists.

**Mode A has two outputs.** One issue per confirmed violation — this lane never fixes code. And, when it writes signature blocks into `docs/craft/`, one pull request carrying only those blocks: an ephemeral runner discards uncommitted work. Never merge it.

Agents echo existing patterns, so a bad one spreads at agent speed.

`docs/craft/dripfeed.md` owns the candidate contract and the live candidate register. **Read it — this skill does not restate it.**

## Modes

**This is the only skill that scans for what is wrong with the codebase.** Both modes find and ticket; neither repairs.

| | **A — rule violations** | **B — deepening candidates** |
| --- | --- | --- |
| Finds | mechanical breaches a query can match | friction no query can match: shallow-module clusters, absent test seams |
| Anchored in | a numbered craft rule or an ADR | the deletion test and ARC-002 |
| Sweep | tree-wide, from a validated signature | the churn hot spots, or the target named for you |
| Output | one issue per confirmed hit | one row in the `docs/craft/dripfeed.md` register |
| Autonomy | `afk` when architecture-preserving Green | never; a deepening changes architecture |
| Runs | §1–§4, nightly cron | §5, on demand |

**Never run both in one pass.** Mode A's success criterion is a tree-wide sweep of a frozen signature; Mode B has no signature to sweep, and mixing them lets a Mode B candidate inherit Mode A's autonomy.

## 1. Signatures

Signatures live beside the rule they enforce: `docs/craft/` is primary, with 85 numbered rules (`ARC-`, `ASH-`, `CSS-`, `ELX-`, `GEN-`, `TST-`, `WEB-`); `docs/adr/` is secondary and optional.

Read [references/signatures.md](references/signatures.md) for the block format and the validation rule.

Check whether any craft rule already carries a `## Violation Signature` block before assuming bootstrap. While none does, *write* them: take rules from the `docs/craft/dripfeed.md` candidate register, which already cites `file:line` evidence, and sign each rule it proves. A register row with no craft rule id gets no signature — log it in the pull request body as a rule gap for `craft-agents-md`.

**A Mode A run succeeds when every signature it adds is swept tree-wide in the same run and each confirmed hit is ticketed.** Signatures without tickets is a half-run: report the gap and open no signature PR.

## 2. Null results

> **A null result is a property of the query until proven otherwise.**

Run each query against a **known instance you did not write it from**, plus one line that must not match, and record the tree-wide hit count. A query validated only against its authoring line passes by construction and measures nothing — that signature is unvalidated: write `Known instance: none — unvalidated` into the block and list it in the signature pull request body.

## 3. Two passes

Two passes with opposite biases, never merged. **Recall** — the cheap mechanical query, tuned to accept false positives. **Precision** — apply the discriminator to every hit, recording each discard with its reason. Write that discard list back into the signature as tomorrow's false-positive library.

**An ADR that requires the shape is not a violation.** CLAUDE.md gives the ADR the win over craft guidance until the decision is deliberately changed. Cite the ADR in the discard list and write it into the discriminator.

## 4. One issue per violation

Title names the rule id. Body carries: the rule quoted, source evidence with `file:line`, the concrete design cost (not a smell name), affected callers, and the verification that would prove behaviour preserved.

Assess per [../\_shared/complexity-assessment.md](../_shared/complexity-assessment.md). **Only architecture-preserving Green candidates get `afk`** — that label triggers `fix-violation`. Anything needing a product or architecture decision gets none, and names the decision it needs. Real labels and their meanings: [triage-labels.md](../../../docs/agents/triage-labels.md).

**Push is a separate authority grant from commit**, and **the signature pull request never auto-merges.**

Check for an open issue on the same rule id and file first, so a nightly run does not duplicate itself.

Preservation is the default, not an absolute: when the smallest correct change unavoidably repairs a latent defect, the candidate stays eligible but **must not be called behaviour-preserving** — state the delta.

## 5. Mode B — deepening candidates

**Scope before you scan.** Deepening pays for itself where change concentrates, so churn picks the target:

```bash
git log --format= --name-only -n 400 | grep -E '^lib/|^test/' | sort | uniq -c | sort -rn | head -30
```

Take the target named for you and skip the churn pass. Scattered churn with no hot spot widens the net; it never licenses scanning the whole tree.

Read `docs/domain/` for the names a good seam should carry, and the active ADRs in that area, before proposing anything.

**The filter is the deletion test** — [deep-modules](../plan-architecture/references/deep-modules.md): would deleting this module push complexity back into several callers, or merely move it? "Merely moves it" is the candidate. That reference also fixes the vocabulary — module, interface, seam, adapter, leverage, locality. "Component", "service", and "boundary" are drift.

Four questions find the candidates:

- Where does understanding one concept mean bouncing between many small modules?
- Where is an interface nearly as complex as the implementation behind it?
- Where was a pure function extracted for testability while the real bugs live in how it is called?
- **Which cluster has no seam to test through, so its tests bind to internals and prove the same thing several times?**

The last one pays most. **Feedback-loop quality caps what an agent can do here**: a cluster testable only function by function produces tests that pass whatever ships, which is why a missing seam is a candidate in its own right and not merely a signal that future work is expensive.

**Output is register rows, never issues.** Append each candidate to `docs/craft/dripfeed.md` under `### Ready`, meeting that file's Candidate Contract, in its columns: candidate, rule, evidence, design cost today. A candidate citing no rule id still belongs in the register — log the rule gap in the pull request body for `craft-agents-md`.

**A deepening never earns `afk` and never self-authorises.** It changes architecture, so Chris picks what lands; `fix-violation` picks up nothing from this mode.

Red flag, and the one loophole worth naming: "this candidate also breaches ARC-002, so it can go out as a Mode A issue." **A candidate found by reading is a Mode B candidate whatever rule it happens to cite.** Mode A autonomy comes from a validated signature swept tree-wide, not from a rule id appearing in the write-up.

**An ADR requiring the current shape closes the candidate.** Cite it in the register's Not eligible section so tomorrow's run does not re-propose it.

## Close

**Name the mode you ran.** Mode A artifacts: the signature pull request and one issue per confirmed violation, each with its URL; next skill `fix-violation`, which `afk` triggers; list every signature left unvalidated. Mode B artifacts: the register rows added and the hot spots they came from; next decision is Chris picking one, and no lane starts on its own. Log `Decision points: none this round.` when nothing needed deciding.

**Learn hook — an output either way.** Name one thing that rubbed, or write "no friction". *Trivial* — a one-line edit to this skill changing no structure — make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
