# Pressure Testing

The full behavioral method, routed from `SKILL.md` §4. Use it for new or changed discipline rules, gates, and evals. A discipline rule asks the agent to resist pressure to skip or rationalise required behavior.

**Core principle: if the baseline agent did not fail without the changed guidance, that guidance has no demonstrated behavioral delta.**

## Evidence record

**Record location:** Name the record before the run — the card's `CONCEPT.md`, a line in `docs/proposals/harness-flywheel.md`, or the task transcript. This repository has no fixture directory; do not name one. The record holds:

- **Task:** frozen request and normal trigger;
- **Pressures:** the combined set;
- **Oracle:** source and binary required outcome;
- **Run controls:** model and version, tool scope, non-skill context, skill-present state;
- **Observation:** the agent's verbatim decision and stated reasons; "no rationale stated" when it gives none;
- **Patch targets:** owning rule, rationalisation counter, red-flag location, description change;
- **Runs:** each patch and its rerun result;
- **Verdict:** final `pass` or `unproven`.

**Oracle custody:** Cite a source fixed before the current change: an observed failure, an independently governed rule, an accepted request, or a separate Chris decision. A source written or weakened inside the same change never qualifies, whatever the edit order. The producer may encode the oracle; an expectation authored after the judged output needs an earlier independent source or a separate Chris acceptance.

## Scenario

**Normal trigger:** Give the agent a real task, not a quiz about the rule. Keep the task prompt, model, tools, and non-skill context fixed. A new skill's baseline omits it; hardening baselines the frozen prior version and substitutes only the changed one.

**Pressure minimum:** Combine three or more pressures for a discipline rule.

| Pressure | Looks like |
| --- | --- |
| Time | "this is blocking release" |
| Sunk cost | "you already wrote most of it" |
| Authority | "Chris said to ship it" |
| Exhaustion | long session, late context |
| Works-already | "manual pass makes test formality" |
| Efficiency | "full suite wastes minutes" |

### Behavioral contract

Use the same confidence path as an application test. Labels stay optional; the causal structure does not.

- **Arrange:** Freeze the evidence record above — task, pressures, evidence, required outcome — before launch.
- **Act:** Invoke the skill with a request that normally triggers it. Reciting the rule or answering a hypothetical is not behavioral evidence.
- **Assert:** Judge the decision or artifact against the frozen binary criterion. Wording and step order matter only when the governing source makes them contract.

**Scenario locality:** A helper may hide harness mechanics. The prompt keeps the pressure, the owner decision, the branch preconditions, and the accepted outcome visible.

**Transfer claim:** After a guidance edit, rerun the exact failed scenario first. Add a blind transfer case only when the rule claims behavior beyond that scenario and overfitting would risk material security, data, release, or workflow harm. It stays separate from exact-regression completion.

## Cycle

**RED — baseline.** Freeze the evidence record, then run the baseline above. A violation hands its transcript and stated reasons to GREEN. Compliance marks the improvement `unproven` and stops — never invent a failure. Drop the claim, or build a stronger scenario from an observed pressure before another RED. Chris may adopt an unproven rule by explicit recorded decision; that still cannot call the hardening verified.

**GREEN — minimal skill.** Write guidance addressing only the stated reasons and observed action. Re-run the exact frozen scenario with the skill present.

**REFACTOR — close loopholes.** Give each new stated reason an explicit counter. Re-run the exact scenario until it holds.

## Hole closure

For each reason the baseline stated, do all four in the target skill or a routed reference:

1. **Negate the reason in the owning rule.** Name the prohibited shortcut and why it fails the contract.
2. **Add the rationale beside the owning rule.** Use the existing rationalisation table when there is one, otherwise a local excuse/counter row. Never write to an unnamed global table.
3. **Add a red flag beside the gate.** Use the phrase the agent stated before the violation as the self-check.
4. **Update the target skill's description.** Add a symptom of the approaching violation so the skill loads before the breach.

**Rerun boundary:** Rerun after any patch that changes a rule, gate, route, prerequisite, scenario, or oracle. Spelling and punctuation fixes do not invalidate a behavioral run.

## Compliance framing

- **Authority:** cite the source of the rule.
- **Commitment:** require a plan before action when abandonment is the failure mode.
- **Specificity:** state the preferred behavior and the reason. Reserve absolutes for irreversibility, security, and data loss.
- **Consistency:** state one rule the same way everywhere.

**Framing limit:** Framing makes a grounded rule stick; it never makes a weak rule strong.

## Completion

**Pass gate:** Run two consecutive skill-present trials on the same frozen task, pressures, oracle, model, and tool scope. Each must meet the binary criterion without a new rationale. Record every stated rationale, the final `pass`, the patch set, and any separate transfer result.

**Failure exit:** If GREEN keeps failing, the rule or the reason is wrong. Return to the source decision instead of adding prose. If the baseline passed, no `pass` verdict exists for the behavioral improvement — record `unproven` and stop.

Worked scenarios: [../examples/pressure-scenarios.md](../examples/pressure-scenarios.md).
