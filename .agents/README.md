# Agent System

Client-neutral skills, exposed to both agents through symlinks:

```text
.claude/skills/          canonical Agent Skills (16) — real files
.claude/skills/_shared/  references used by more than one skill
.agents/skills           relative symlink to ../.claude/skills
.codex/skills            relative symlink to ../.claude/skills
.claude/agents/          Claude-native taste, reader, and review agents (16)
.codex/agents/           Codex mirrors of the roles Codex runs (10)
.agents/hooks/           client-neutral lifecycle and repository setup hooks
.agents/bin/             harness consistency check
```

**The canonical directory is `.claude/skills`, and that is not cosmetic.** Claude Code running in GitHub Actions does not resolve symlinks, so a symlinked `.claude/skills` loses every skill in the headless runs the maintenance lanes depend on. Codex reads `.agents/skills` and `.codex/skills`, and resolves the symlinks fine, so the indirection is pushed onto that side. Do not invert this back.

Every skill is a directory with a `SKILL.md` carrying Agent Skills frontmatter. Only the two specification fields are used: `name` and `description`. See the [Agent Skills documentation index](https://agentskills.io/llms.txt).

**There is no router, no dispatcher, and no route contract.** Descriptions do the routing. A skill earns its place by having a trigger no other skill's description would catch; overlapping descriptions make routing ambiguous and eat the listing budget.

## The budget that constrains this

Codex spends at most 2% of the context window — **8,000 characters when the window is unknown** — listing skill names and descriptions, and shortens descriptions before dropping skills. Exceed it and routing degrades on Codex before you notice anything on Claude.

```sh
# name + description characters across the harness
.agents/bin/check-harness.sh
```

This harness holds 16 skills and roughly 3,600 characters — about 45% of budget. That headroom, more than any question of taste, is why the set stays small.

Dependency usage rules are deliberately **not** skills. `mix.exs` generates `skills/build/references/backend/dependencies.md`, a link index that `build` loads when it needs one; regenerate with `mix usage_rules.sync --yes`.

Run `.agents/bin/check-harness.sh` after any change: frontmatter, SKILL.md size, link resolution, the listing budget, and the client symlinks.

## Agents

Per-taste files rather than one parameterised variant, so each bias lives in its own prompt. All are read-only, cannot delegate, and return evidence; the main agent alone synthesises and mutates state.

Three mechanisms, described once in [`_shared/diverge-converge.md`](skills/_shared/diverge-converge.md): **angles** (one artifact, different lens — needs a verify ladder), **tastes** (one brief, different bias — no ladder), **defects** (one document, a broken reader — the defect is the finding).

Codex receives only the roles it runs: review roles, bug-fix tastes, reader defects. Design and architecture tastes are Claude-side because `shape` and `plan-architecture` are moderated phases.

## Changing the harness

Use `craft-skills` or `craft-agents-md`. Both close with a defective-reader panel; a skill is not done until it survives one.
