---
name: craft-agents-md
description: Use when writing or revising AGENTS.md at any level of the repository, when guidance has grown stale or contradicts the code, or when startup context needs to get smaller.
---

# Craft AGENTS.md

**Stance: co-developed.** Same escalation triggers as [../craft-skills/SKILL.md](../craft-skills/SKILL.md) §2 — stop at design boundaries, log `Decided: X by Chris`, and say `Decision points: none this round.` when none fired.

Undefined terms — stance, `Decided:` — live in [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` are relative to the repository root, not this file.**

`CLAUDE.md` symlinks to `AGENTS.md`. Never edit them separately.

## 1. Classify every line

Test each line, including lines already there:

| Class | Test | Evidence the line must carry | Action |
| --- | --- | --- | --- |
| **OBVIOUS** | derivable from `ls`, `--help`, or framework convention | none possible | **cut** |
| **GOTCHA** | repo-specific failure mode costing a wasted turn | the wasted turn or incident it prevents | keep |
| **TASTE** | counter to industry default | the default it counters | keep |
| **POINTER** | depth someone occasionally needs | a path that resolves | keep |

**No evidence, no label — the line is OBVIOUS**, however useful it feels.

Prose rules apply to every line you keep: [../\_shared/writing.md](../_shared/writing.md), plus one paragraph per line — [../craft-skills/references/skill-anatomy.md](../craft-skills/references/skill-anatomy.md). Check with `../craft-skills/scripts/check-prose.sh AGENTS.md`.

## 2. Rules

- **Never restate.** Skip `--help`, README, or a file already in context. "See the pre-commit hook in `.claude/settings.json`" costs fewer tokens and stays current.
- **Partition by recoverability, not importance.** Drop anything recoverable from a neighbouring file. Prioritise deprecated patterns that code will copy, and hard-enforced CI checks.
- **Phrase as defaults with a reason.** "Prefer X over Y, because Z" travels to unforeseen cases; a bare "never" does not. Reserve absolutes for irreversibility, security, and data loss.
- **Real repo paths, not invented examples.** A broken real path fails loudly; a fabricated one fails silently.
- **Never duplicate a hook-enforced rule.** Pre-commit enforces it; saying so again is dead weight.

## 3. Required lines

1. **The status of the file itself** — code can contradict guidance; flag the conflict rather than silently obeying or routing around it.
2. **Working norms** — how hard to push back, whether to polish before submitting, that "works" is not "finished".

## 4. Size

Target **~100 lines**, measured with `wc -l AGENTS.md`. `AGENTS.md` is nearest-file-wins, so a subdirectory can carry its own without inflating the root. Justify each addition.

**Both constraints bind.** This file has its own target, and [../craft-skills/SKILL.md](../craft-skills/SKILL.md) §7 owns the Codex skill-listing budget. Neither excuses the other.

## 5. Verify — always

- Resolve **every** path, link, and cited exemplar. A dead path is the commonest defect in these files.
- Read version numbers and constants from their authoritative source, not memory.
- Check for contradictions inside the file **and against every ancestor and descendant `AGENTS.md`**. Nearest-file-wins hides a parent/child conflict from any single read.
- Verify each documented command is real — via `--help`, `--dry-run`, or the task source. **Skip deploy, migration, and credential-bearing commands.**

## 6. CLOSE — the defective-reader panel

Run [../craft-skills/SKILL.md](../craft-skills/SKILL.md) §4, including its rule that a behavioral change first completes [../craft-skills/references/pressure-testing.md](../craft-skills/references/pressure-testing.md). The panel matters more here, because this file is always-on. Spawn three of its five readers — `reader-literalist`, `reader-skimmer`, `reader-rationalizer` in `.claude/agents/` — and weight the skimmer, since most agents read AGENTS.md that way.

Whatever the skimmer drops must move up, get bolded, or be cut. **Name each reader you spawned and paste its finding list; a single-pass inline run must say so.**

## Close

Report what changed and what was cut in `AGENTS.md` and any nested one you touched, each with its path and new `wc -l` count. Log `Decided: X by Chris` or `Decision points: none this round.` Nothing auto-chains; no next skill follows.

**Learn hook — an output either way.** Name one thing that rubbed, or write "no friction". *Trivial* means a one-line edit to this skill changing no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
