---
name: craft-skills
description: Use when creating, editing, reviewing, hardening, or pruning an agent skill, when a skill produced friction, or when a passing structural check is claimed as behavioral proof.
---

# Craft Skills

**Stance: co-developed.** Autonomous while working; **stop at design boundaries** — see §2.

[../\_shared/vocabulary.md](../_shared/vocabulary.md) defines stance, oracle, predicate, corpus, and the `Decided:` rule. **Bare paths like `docs/craft/` start at the repository root, not here.**

> **Skills improve through use, not through thought.**

Never write a skill in the abstract. Develop each version against a real target; skill and output improve together.

## 1. OPEN — co-develop against a real target

Pick a target you care about, **run the skill on it**, and edit mid-flight:

- **Friction** — the skill failed to guide you → add what would have helped
- **Gaps** — decisions it did not cover → add them
- **Waste** — guidance that did not help → delete it

Do not wait until the target is done. The mid-flight edit is the mechanism.

**Bootstrapping:** v0 will be wrong. That is the point — take a stab.

## 2. Escalation triggers — STOP and present

| Trigger | Example |
| --- | --- |
| Design tradeoff | simple-but-limited vs complex-but-complete |
| Scope change | the fix would change the skill's purpose |
| "By design" | marking something intentional rather than fixing it |
| Repeated issue | the same problem surfaces 2+ rounds |
| Accepting a limitation | documenting a gap instead of closing it |
| Architectural choice | affects the harness's structure |

**Carry an open-problem list between rounds and compare against it.** Renaming a problem does not make it new, and re-wording never dodges a trigger.

Present options with pros, cons, and a recommendation, then wait for an explicit answer. Log `Decided: X by Chris` quoting his words; without a quote, write `Awaiting decision: <question>` and stop.

**When nothing fired, say so:** `Decision points: none this round.` Silence must not masquerade as compliance.

## 3. Form

Frontmatter, naming, degrees of freedom, disclosure tiers, cross-reference syntax: [references/skill-anatomy.md](references/skill-anatomy.md). Where a sentence belongs and what it costs there: [references/context-frugal-writing.md](references/context-frugal-writing.md).

Prose rules for every artifact — banned forms, the paramedic method, heading style: [../\_shared/writing.md](../_shared/writing.md). Run `scripts/check-prose.sh` for `file:line` JSON; hand the findings to `reader-editor` to rewrite.

**The script owns six of the eight banned forms:** amplification, hedge, correlative conjunction, action-oriented heading, introductory clause, nominalisation. Cliffhanger and time trick have no regex; the amplification list omits `just` and `exactly`, usually load-bearing. `reader-editor` owns those four.

Worked pressure scenarios: [examples/pressure-scenarios.md](examples/pressure-scenarios.md).

The two broken most often:

- **A description states triggers only — never the workflow.** A process summary creates a shortcut the agent takes instead of reading the skill.
- **The routing table stays in `SKILL.md`.** Defer content, never the index; a reader who skips the index never learns the references exist.

## 4. CLOSE — the defective-reader panel

**A skill is not done until it survives the reader panel.** Classify each change by effect first: an edit is behavioral when it changes what the agent must decide or do, what may be skipped under pressure, or what counts as success. A label like "editorial" or "routing" does not override that effect.

**A behavioral change first completes [references/pressure-testing.md](references/pressure-testing.md).** Freeze the draft, then run the panel. Structural, editorial, routing, and link-only changes that preserve behavior and the success criterion start at the panel. A later structural patch invalidates earlier reader reports and forces a rerun.

**Run panel:** Spawn readers against the frozen draft using [../\_shared/diverge-converge.md](../_shared/diverge-converge.md). **Name every reader you spawned and paste its finding list.** **A run that could not spawn subagents says so and calls itself a single inline pass, never a panel.**

| Reader | Surfaces | Patch by |
| --- | --- | --- |
| `reader-literalist` | undefined terms, missing context, unstated prerequisites | defining them inline |
| `reader-skimmer` | buried constraints | **whatever the skimmer drops must move up or be bolded** |
| `reader-rationalizer` | unenforced gates | an acceptance test or an explicit consent rule |
| `reader-process-reflector` | missing handoffs between steps (workflow skills only) | naming the handoff |
| `reader-editor` | buried actions, padding, banned sentence forms | the rewrite it hands you |

Patch against their lists. **Re-run after any patch that moves, adds, removes, or changes a rule, gate, route, or prerequisite.** Spelling and punctuation fixes do not invalidate a read.

## 5. Eval evidence

The producing agent grades its own complexity verdicts, sweep results, and "no friction" claims. **A runnable check repeats a predicate; it does not make that predicate independent.** Encode mechanical facts as scripts: `grep -c` a banned pattern, `wc -l` against a limit, `jq -e` a schema. Judge pass or fail against the stated criterion and name the fix. Never score it.

Structural checks: `.agents/bin/check-harness.sh` owns frontmatter, SKILL.md size, links, the listing budget, and topology. `scripts/check-prose.sh` owns the six banned forms named in §3. The ~300-line reference cap has no owner — measure it with `wc -l`. Extend the script that owns a predicate; an unowned predicate needs a named script and a failure output. Loop until clean or escalate under §2. **Claim only what a script executes.**

Behavioral evidence: run the skill through its normal trigger on a real task, then judge what it produces. **Freeze the scenario and oracle in the prompt or card beforehand.** The oracle cites a source fixed before this change: an observed failure, an independently governed rule, an accepted request, or a separate Chris decision. **A source written or weakened inside this change does not qualify, and the producing agent may encode the oracle but never derive one from the artifact or weaken it.** **On a new skill's first run, that source is the v0 target's observed failure** — name it. A different agent reduces bias only while the evidence and binary criterion stay fixed.

**Red flag:** "Script and reader pass, so behavioral hardening is complete." Structural green does not supply behavioral evidence.

Goalpost change: editing the scenario, oracle, corpus, threshold, exclusion, checker, snapshot, or accepted baseline **redefines the proof.** Record an independently governed source fixed before this change, or a separate Chris acceptance, plus the case delta, then rerun the affected evidence. Reordering the change so the source edit comes first grounds nothing. **Previous green does not transfer; new green cannot justify a weakened predicate.**

Baseline model: use the model Chris names, or the current one when he names none, and record it with its version. Keep the task prompt, tools, and non-skill context identical across both runs. A new skill's baseline omits the target skill; the skill-present run adds it. Hardening baselines the frozen prior version and substitutes the changed version. If the baseline complies, drop the behavioral-improvement claim, or strengthen the scenario from an observed pressure and rerun. **An explicit Chris decision may adopt a normative rule as `unproven`; it cannot call hardening verified.**

## 6. Structure emerges; it is not designed

Do not design structure upfront. Let friction pull it out:

| Signal | Response |
| --- | --- |
| Same failure recurs | add an eval check |
| Output varies run to run | add a template or a constraint |
| Guidance feels like overhead | remove or loosen it |
| A decision feels arbitrary | add rubric criteria |
| The skill gets misused | name what to get right |

Log every failure you hit in [references/failure-modes.md](references/failure-modes.md) — symptom, cause, fix. That table is this skill's most valuable output and the one part nobody can write in advance.

**Mature when:** changes shrink, new targets stop revealing new failure modes, outputs pass eval first or second try, and someone else succeeds with it. Mature is not frozen.

## 7. Pruning

Deleting a skill counts as much as writing one. A skill earns its slot with a trigger no other skill's description catches. Overlapping descriptions cost more than a missing skill: they blur routing and eat the listing budget.

Check the budget: `name` + `description` across the harness must stay under **8,000 characters**, or Codex truncates descriptions and routing degrades.

```bash
.agents/bin/check-harness.sh
```

That script measures the real character total, resolves every relative link, and checks frontmatter and SKILL.md size. `find | wc -l` counts files, not budget.

## Close

Name every changed file with its path, what changed and why, and the natural next skill. Nothing auto-chains. Log `Decided: X by Chris` quoting his words, `Awaiting decision: <question>`, or `Decision points: none this round.`

**Learn hook — it produces an output either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill that changes no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not an exit from the other two.
