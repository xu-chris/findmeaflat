#!/usr/bin/env bash
# Install worktree-aware git hooks into the shared hooks directory.
#
# Why this exists: git_hooks (the Elixir lib) bakes a hardcoded absolute path
# into .git/hooks/* and re-bakes it on every `mix compile` (auto_install). Git
# worktrees SHARE .git/hooks, so that hardcoded path makes a commit/push from a
# worktree run the gate against the wrong checkout (e.g. main + its WIP). We
# disable git_hooks auto_install (config/config.exs) and install these hooks
# instead: each one cd's to the checkout where the commit/push actually happens,
# then delegates to `mix git_hooks.run`, which reads the configured tasks
# (mix precommit / mix ci).
#
# Idempotent. Run from anywhere inside the repo (main or a worktree); it always
# targets the shared hooks dir, so installing once covers every worktree.
set -euo pipefail

# Resolve the shared hooks directory (absolute), shared by all worktrees.
git_common="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
hooks_dir="$git_common/hooks"
mkdir -p "$hooks_dir"

write_hook() {
  local name="$1" event="$2"
  cat > "$hooks_dir/$name" <<EOF
#!/bin/sh
# Worktree-aware git hook — installed by .agents/hooks/install-git-hooks.sh.
# Runs the gate against the checkout where the commit/push happens, not a
# baked-in path. Do not let git_hooks auto_install overwrite this (it is off).
cd "\$(git rev-parse --show-toplevel)" || exit 1
mix git_hooks.run $event "\$@"
EOF
  chmod +x "$hooks_dir/$name"
}

write_hook pre-commit pre_commit
write_hook pre-push pre_push

echo "Installed worktree-aware git hooks in $hooks_dir (pre-commit, pre-push)"
