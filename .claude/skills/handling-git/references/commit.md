# Commit

> A commit records **one coherent, verified concern**. It grants no permission to pull, rebase, push, open a PR, or absorb unrelated worktree changes.

## 1. Resolve scope

Name the exact files from the conversation, the proposal's `PLAN.md` or `CONCEPT.md`, and the diff. Inspect `git status --short`, both diffs, the branch, and recent history first.

Every unrelated modification and untracked file is Chris's. Leave them untouched.

**Stop and ask when** the file set is ambiguous, holds unresolved conflicts, omits production code that staged tests need, or mixes concerns that cannot stand alone.

## 2. Verification ownership

**If `.git/hooks/pre-commit` is absent, the gate is uninstalled: run `bash .agents/hooks/install-git-hooks.sh` before committing.** A fresh clone and a cloud runner both start without it; a commit made without it was never gated.

Trace `.git/hooks/pre-commit` through `config/config.exs` to its current alias in `mix.exs`. Run focused checks against changed behavior before staging; replaying the canonical alias command by command is not focused. **On a commit request, let `git commit` run the hook-owned gate once; never invoke that gate manually before or after, even as a control.** Run the full gate directly only without a commit request, or when diagnosing the gate itself.

Review every selected diff yourself: no secret, credential, generated noise, temporary trace, unrelated formatting, or unstaged dependency.

Keep commits buildable and behaviourally coherent. Never WIP-commit merely to enable a pull or rebase.

## 3. Stage exact paths

```bash
git add -- path/one.ex path/two_test.exs
git diff --cached --stat
git diff --cached
```

If staging caught anything out of scope, unstage that path and re-check. Never use a broad add as a shortcut.

## 4. Write the message

`type: concise outcome`, or `type(scope): concise outcome` when a stable scope adds clarity. Types: the list in `.gitmessage`. Type implies no version bump.

Issue references go in the description or footer, never the scope. Add a body when the diff hides the rationale, compatibility impact, migration, or trade-off.

Describe repository intent plainly.

## 5. Commit, then inspect

One non-interactive commit. **Never disable, replace, or bypass the hook.**

**Caveat for this repository:** the hooks installed by `.agents/hooks/install-git-hooks.sh` delegate to `mix git_hooks.run`, which **cannot run until an Elixir project exists**. Until then there is no canonical gate — report that plainly rather than claiming a pass that never happened, and do not install the hooks expecting them to work.

Once the gate exists: a missing marker means the commit is unverified — reset it, install or repair the hook, commit again. Inspecting the configuration and leaving the commit standing resolves nothing. On a hook failure, leave the failed state visible, fix only in-scope causes, restage the exact paths, retry.

Report the hash, subject, files, what verified it, and what remains in the worktree.

## 6. Push only when separately authorized

Inspect branch and upstream, then push the exact current branch. **Never pull or rebase automatically** before or after committing.

New branches take `feature/`, `fix/`, or `docs/` plus the issue number and title. Once the Elixir project exists, `git push` runs `mix ci` through the pre-push hook — **never run that gate manually before or after a push.** This repository also follows Conventional Commits 1.0.0 (see `.gitmessage`).

If the remote rejects the push, report the divergence and ask before any history-changing integration.
