# Skill Anatomy

> Form, not process. What a skill file *is*; `SKILL.md` covers how to develop one.

Distilled from Anthropic's skill-authoring guidance and the agentskills.io specification.

## Frontmatter

Only `name` and `description` carry meaning; this harness uses nothing else the specification allows.

`name` — letters, numbers and hyphens only, **verb-first**: `creating-skills`, not `skill-creation`. Name by what you *do* or by the core insight: `condition-based-waiting` beats `async-test-helpers`; `root-cause-tracing` beats `debugging-techniques`. Gerunds suit processes.

`description` — third person, starts with "Use when", and states **triggering conditions only**.

> **Never summarise the workflow in the description.** A process summary creates a shortcut the agent takes *instead of reading the skill*. Tested: "code review between tasks" produced one review where the body specified two; dropping the summary produced both.

Name concrete triggers, symptoms, and situations. Describe the *problem* ("tests pass inconsistently"), not a language-specific symptom ("tests use `setTimeout`") — unless the skill is technology-specific, which the trigger then says.

## Degrees of freedom

Match specificity to the task's fragility and variability.

| Freedom | Use when | Form |
| --- | --- | --- |
| **High** | many approaches valid, context decides | prose steps and heuristics |
| **Medium** | a preferred pattern exists, some variation fine | a template or a parameterised snippet |
| **Low** | one correct sequence, fragile or irreversible | an exact command, or a script the agent runs rather than reads |

Over-specifying a high-freedom task breaks the skill on the first unforeseen case. Under-specifying a low-freedom one leaves a skill that reads correct while the job goes wrong.

**When a step is mechanical and checkable, prefer a script.** A script executes rather than loads: no context cost, no misreading.

## Progressive disclosure

`SKILL.md` is a table of contents with decision points, not a manual.

| Level | Cost | Holds |
| --- | --- | --- |
| `description` | always in context | triggers only |
| `SKILL.md` body | loaded when triggered | the workflow, the decision points, the routing table |
| `references/*.md` | loaded only when a named condition is true | method, taxonomies, deep reference |
| `scripts/*` | executed, never loaded | anything mechanical |
| `examples/*` | loaded when someone needs a worked case | one good example, not five mediocre ones |

**The routing table itself stays in `SKILL.md`.** Defer the index and the agent must load a file to learn which files to load; a skimming reader never learns the references exist.

This harness caps `SKILL.md` at **150 lines**, enforced by `.agents/bin/check-harness.sh`. Project references target about **300 lines**; nothing enforces that one, so measure it with `wc -l`.

## Cross-references

Name the skill or file and mark whether it is required. Inside a `SKILL.md`, where `references/` sits one level down:

```markdown
**Required:** read references/pressure-testing.md before writing the skill.
Failure modes seen so far: [references/failure-modes.md](references/failure-modes.md).
```

Both name real files in `craft-skills`. Invented paths fail silently; real ones fail loudly the moment they rot, which is the argument for them. `.agents/bin/check-harness.sh` resolves every link in the harness on each run.

**Never `@path` syntax.** It force-loads immediately and burns the context you were deferring.

## Line breaks

**Write each paragraph as one line.** Editors soft-wrap and previews reflow, so manual breaks buy nothing and cost twice: `rg` matches a line, so a sentence split across three needs three reads, and every reflow churns the diff.

Wrap nothing except what is already line-based — table rows, list items, code.

## What does not belong in a skill

- A narrative of how you solved something once. A skill is reusable technique, not history.
- The same example in five languages. One excellent, complete, runnable example is enough.
- Anything a `--help`, a neighbouring file, or a dependency's `usage-rules.md` already says. Point at the authority: fewer tokens, and it stays current.
- A mechanical constraint a regex or a script could enforce. Automate it and save the prose for judgement calls.
