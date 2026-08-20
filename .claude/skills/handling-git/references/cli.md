# git and gh Recipes

> Commands whose flags are easy to get wrong or forget. Everything else: `git help <cmd>`, `gh <cmd> --help`.

## Seeing what you are about to do

```bash
git status --short                   # concise, script-friendly
git diff --cached                    # exactly what a commit would record
git diff @{upstream}...HEAD          # your commits, excluding theirs
git log --oneline --graph --decorate -20
git show --stat <ref>
```

`...` (three dots) against upstream answers "what did I add" rather than "how do the tips differ".

## Finding out why a line exists

```bash
git log -L <start>,<end>:<file>      # history of one region
git log -S '<string>' -- <path>      # commits that changed occurrences of a string
git blame -w -C <file>               # ignore whitespace, follow moved code
```

`-S` finds where behaviour was introduced or removed. `git blame -C` survives a refactor that moved the code.

## Branches and worktrees

Each worktree runs its own database and HTTP port, provisioned by `.agents/hooks/elixir-worktree-setup.sh` and driven by `.config/wt.toml`. **Use `wt` for worktree lifecycle**, not raw `git worktree`, or the isolation is skipped.

```bash
git branch --show-current
git for-each-ref --sort=-committerdate --format='%(refname:short) %(committerdate:relative)' refs/heads/
```

## Recovering

```bash
git reflog                           # where HEAD has been; almost nothing is lost
git restore --staged -- <path>       # unstage, keep the change
git restore --source=HEAD -- <path>  # discard the change  (destructive)
```

**`git checkout -- <file>` and `git restore --source=…` discard unstaged work with no undo.** Never use either to undo an edit you made this session — re-edit instead. `git stash` is off limits entirely: it hides Chris's work where he is not looking.

## gh

```bash
gh issue view <n> --comments
gh issue list --state all --search "<term>" --json number,title,state,url
gh pr checks <n>
gh run view <id> --log-failed        # only the failing step's log
gh label list
```

`gh run view --log-failed` skips straight to the failing step — the biggest time saver on a red build.

Numbers are shared between issues and PRs. Resolve an ambiguous `#42` with `gh pr view 42`, falling back to `gh issue view 42`.
