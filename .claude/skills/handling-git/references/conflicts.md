# Merge and Rebase Conflicts

> A stopped merge or rebase with conflict markers in the working tree.

## 1. See the current state

Which operation stopped, where, and which files carry markers:

```bash
git status --short
git log --oneline --left-right --merge
git diff --diff-filter=U
```

`--merge` shows only the commits that differ between the two sides — the set whose intent you need.

## 2. Find the primary source of each side

For every conflicting hunk, learn **why each change was made**. Read the commit messages, then the PR, then the originating issue. `git log -L <start>,<end>:<file>` traces one region's history directly.

A conflict resolved without both intents is a guess that compiles.

## 3. Resolve each hunk

Read the references under `.claude/skills/build/references/` matching the conflicted surfaces, plus the relevant `docs/craft/` rules and any active ADR for that area.

- **Preserve both intents where possible.**
- Where they clash, pick the one matching the merge's stated goal and **note the trade-off** in the report.
- **Never invent new behaviour** to bridge two sides. A reconciliation needing a decision neither side made is Chris's decision.
- If intent cannot be reconciled safely, **stop and ask.** Do not abort the merge unless asked — an abort throws away the resolution work already done.

## 4. Verify proportionally

Format only supported Elixir source and test files. Run focused `mix test` on the affected area, then compile or run broader gates in proportion to the conflict's risk. Run compile-capable commands one at a time.

**Fix only breakage the resolution introduced.** Report unrelated drift; do not repair it in the same pass.

## 5. Report

State the resolved files, which intent won where and why, what verification ran, and the exact command still outstanding — `git add`, `git rebase --continue`, `git merge --continue`.

**Resolving files does not authorize staging, committing, or continuing the operation.** Those are separate rungs on the authority ladder.
