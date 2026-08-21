#!/usr/bin/env bash
# Hook: SessionStart — bring a cloud session's services up.
#
# The environment setup script (.agents/cloud/setup-script.sh, pasted into the
# cloud environment's "Setup script" field) installs Erlang/OTP, Elixir and
# PostgreSQL once, and Anthropic snapshots the filesystem afterwards. The
# snapshot keeps FILES, never PROCESSES — so the database is installed but
# stopped at the start of every session, and something has to start it.
#
# That something is this hook. It is a no-op outside a cloud container, so it
# costs a local session nothing.
#
# It reports through additionalContext rather than stdout because a session that
# begins with a silently missing database wastes the first several tool calls
# discovering that fact.

set -uo pipefail

STATE_DIR=/usr/local/share/findmeaflat-cloud
SETUP_LOG=/var/log/findmeaflat-cloud-setup.log

# Not a cloud container provisioned by our setup script: nothing to do.
[ -d "$STATE_DIR" ] || exit 0

HOOK_PAYLOAD="$(cat 2>/dev/null || true)"
HOOK_EVENT="SessionStart"
if command -v jq >/dev/null 2>&1 && [ -n "$HOOK_PAYLOAD" ]; then
  detected=$(printf '%s' "$HOOK_PAYLOAD" | jq -r '.hook_event_name // .hookEventName // empty' 2>/dev/null || true)
  [ -n "$detected" ] && HOOK_EVENT="$detected"
fi

emit_context() {
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg msg "$1" --arg event "$HOOK_EVENT" \
      '{hookSpecificOutput: {hookEventName: $event, additionalContext: $msg}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":%s}}\n' \
      "$HOOK_EVENT" \
      "$(printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"
  fi
}

# Defaults matching the setup script, overridden by whatever it recorded.
FINDMEAFLAT_SETUP_STATUS=unknown
FINDMEAFLAT_PG_VERSION=18
FINDMEAFLAT_PG_PORT=5434
# shellcheck disable=SC1091  # written at environment-build time, not in the repo
[ -f "$STATE_DIR/env" ] && . "$STATE_DIR/env"

notes=()

# --- PostgreSQL ------------------------------------------------------------
if command -v pg_isready >/dev/null 2>&1 && pg_isready -q -p "$FINDMEAFLAT_PG_PORT" 2>/dev/null; then
  notes+=("PostgreSQL already up on port $FINDMEAFLAT_PG_PORT.")
elif command -v pg_ctlcluster >/dev/null 2>&1; then
  if pg_ctlcluster "$FINDMEAFLAT_PG_VERSION" main start >/dev/null 2>&1; then
    notes+=("Started PostgreSQL $FINDMEAFLAT_PG_VERSION on port $FINDMEAFLAT_PG_PORT (user postgres, password postgres).")
  else
    notes+=("FAILED to start PostgreSQL $FINDMEAFLAT_PG_VERSION. Database-backed work and \`mix test\` will not run. Setup log: $SETUP_LOG")
  fi
else
  notes+=("No pg_ctlcluster on PATH — PostgreSQL was not installed by the environment setup script. Setup log: $SETUP_LOG")
fi

# --- Toolchain -------------------------------------------------------------
if command -v elixir >/dev/null 2>&1; then
  notes+=("Elixir: $(elixir --version 2>/dev/null | tail -1)")
else
  notes+=("Elixir is NOT installed. The environment setup script did not complete. Setup log: $SETUP_LOG")
fi

# --- Degraded build --------------------------------------------------------
if [ "$FINDMEAFLAT_SETUP_STATUS" != "ok" ]; then
  notes+=("Environment setup finished with status '$FINDMEAFLAT_SETUP_STATUS'. Read $SETUP_LOG before trusting the toolchain.")
fi

printf -v joined '%s\n' "${notes[@]}"
emit_context "Cloud session environment:

$joined
Repository conventions: AGENTS.md. Cloud specifics: docs/agents/cloud-sessions.md."
exit 0
