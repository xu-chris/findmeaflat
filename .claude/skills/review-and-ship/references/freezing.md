# Freezing the Artifact

> Step 0, unskippable. Every reviewer gets the identical packet; only the main agent resolves scope, synthesises, and changes state.

## Review mode

1. A caller-supplied PR, ref range, branch, commit, or path, **when it resolves unambiguously**.
2. Otherwise `git diff @{upstream}...HEAD`; fall back to the default-branch merge-base, then `git diff HEAD~1`.
3. **Uncommitted changes, or an empty range diff, also need** `git diff HEAD` and `git status --short` — review often runs before the commit, and a range-only diff reviews nothing.

## Record the packet

Write the exact commands, the fixed baseline, the commit list, and the unified diff into a neutral packet **outside the repository** — the session scratchpad, else `$(mktemp -d)`. Report its path. A packet inside the repository joins the next diff, and reviewers review their own notes.

## Stop conditions

Stop on an invalid target, or on an empty artifact — range diff, working-tree diff, and `git status --short` **all three** empty.

Empty is a fact about the diff, not a judgement about whether the change looks worth reviewing. A one-line diff is small, not empty.
