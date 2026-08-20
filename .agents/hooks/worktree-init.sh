#!/usr/bin/env bash
# Hook: SessionStart — when a session boots inside a git worktree (created by
# worktrunk's `wt switch --create`, the WorktreeCreate hook, or manually),
# provision it with an isolated dev/test database + HTTP port so parallel
# worktrees don't collide with main or each other. Idempotent: exits silently
# if .claude/worktree.md already exists.
#
# WorktreeCreate/WorktreeRemove are owned by the worktrunk plugin (`wt switch
# --create` / `wt remove`); this project's isolation setup instead runs via a
# `pre-start`/`pre-remove` project hook in .config/wt.toml, which is the
# primary path. This SessionStart hook is a safety net for sessions that
# attach to a worktree without going through that hook (e.g. `wt` invoked
# outside Claude Code, or WORKTREE_SKIP_DB set at creation time).
#
# Delegates the heavy lifting to elixir-worktree-setup.sh in the same directory.
# Self-contained — no external tooling beyond git, jq, and perl.

set -uo pipefail

HOOK_PAYLOAD="$(cat 2>/dev/null || true)"
HOOK_EVENT="SessionStart"
if command -v jq >/dev/null 2>&1 && [ -n "$HOOK_PAYLOAD" ]; then
  detected=$(printf '%s' "$HOOK_PAYLOAD" | jq -r '.hook_event_name // .hookEventName // empty' 2>/dev/null || true)
  if [ -n "$detected" ]; then
    HOOK_EVENT="$detected"
  fi
fi

# Setup script lives alongside this hook so the isolation flow is self-contained.
SETUP_SCRIPT="$(cd "$(dirname "$0")" && pwd)/elixir-worktree-setup.sh"

WORKTREE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$WORKTREE_ROOT" ]; then
  exit 0
fi

# Detect a linked (non-primary) git worktree, regardless of path layout: the
# primary checkout's git-common-dir is ".git" (relative); a linked worktree's
# resolves to the shared .git directory elsewhere.
GIT_COMMON_DIR="$(git -C "$WORKTREE_ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
if [ -z "$GIT_COMMON_DIR" ] || [ "$GIT_COMMON_DIR" = ".git" ]; then
  exit 0
fi

# Already set up?
if [ -f "$WORKTREE_ROOT/.claude/worktree.md" ]; then
  exit 0
fi

emit_context() {
  # Emit an additionalContext message keyed to the triggering event.
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg msg "$1" --arg event "$HOOK_EVENT" '{
      hookSpecificOutput: {
        hookEventName: $event,
        additionalContext: $msg
      }
    }'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":%s}}\n' \
      "$HOOK_EVENT" \
      "$(printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  fi
}

if [ ! -f "$SETUP_SCRIPT" ]; then
  emit_context "Worktree setup script missing at $SETUP_SCRIPT. Without setup, this worktree shares the default port and database with the main worktree."
  exit 0
fi

# Derive from the branch name, matching .config/wt.toml's pre-start hook
# ({{ branch | sanitize }}) so a session that attaches after a failed/skipped
# pre-start reuses the same database name instead of creating a divergent one.
WORKTREE_NAME="$(git -C "$WORKTREE_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-' || true)"
[ -z "$WORKTREE_NAME" ] && WORKTREE_NAME="$(basename "$WORKTREE_ROOT")"

set +e
SETUP_LOG="$(bash "$SETUP_SCRIPT" setup "$WORKTREE_ROOT" "$WORKTREE_NAME" 2>&1)"
SETUP_STATUS=$?
set -e

if [ "$SETUP_STATUS" -ne 0 ]; then
  emit_context "Worktree auto-setup FAILED (exit $SETUP_STATUS). Run manually to diagnose: bash $SETUP_SCRIPT setup \"$WORKTREE_ROOT\" \"$WORKTREE_NAME\"

Setup output:
$SETUP_LOG"
  exit 0
fi

if [ -f "$WORKTREE_ROOT/.claude/worktree.md" ]; then
  # Belt-and-suspenders: patch .claude/launch.json port to match the worktree.
  LAUNCH_JSON="$WORKTREE_ROOT/.claude/launch.json"
  if [ -f "$LAUNCH_JSON" ] && command -v jq >/dev/null 2>&1; then
    WORKTREE_PORT="$(perl -ne 'print "$1\n" if /Dev server port[^0-9]*(\d+)/' "$WORKTREE_ROOT/.claude/worktree.md" | head -1)"
    if [ -n "$WORKTREE_PORT" ]; then
      tmp="$(mktemp)"
      # Patch `url` alongside `port`: the preview tool requires a localhost url
      # to match its entry's port, so updating one without the other produces a
      # config that fails to attach.
      if jq --argjson port "$WORKTREE_PORT" \
          '(.configurations[] | select(has("port")) | .port) = $port
           | (.configurations[] | select(has("url")) | .url) |=
               (if test("^https?://(localhost|127\\.0\\.0\\.1)(:[0-9]+)?/?$")
                then sub(":[0-9]+$|/$"; "") | sub("$"; ":" + ($port|tostring))
                else . end)' \
          "$LAUNCH_JSON" > "$tmp"; then
        mv "$tmp" "$LAUNCH_JSON"
        git -C "$WORKTREE_ROOT" update-index --assume-unchanged .claude/launch.json 2>/dev/null || true
      else
        rm -f "$tmp"
      fi
    fi
  fi

  emit_context "Worktree auto-initialized with isolated DB + port. Details:

$(cat "$WORKTREE_ROOT/.claude/worktree.md")"
else
  emit_context "Worktree setup script ran (exit 0) but did not produce .claude/worktree.md. Check the setup script manually."
fi

exit 0
