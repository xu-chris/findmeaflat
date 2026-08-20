#!/usr/bin/env bash
# Setup script for Claude Code cloud sessions (claude.ai/code).
#
# Point your cloud environment's setup script at this file:
#
#     bash .github/scripts/cloud-setup.sh
#
# Idempotent: safe to re-run. Every step reports what it did, because a cloud
# session that starts subtly wrong is far more expensive to debug than one that
# fails loudly here.
#
# What a cloud session needs that a fresh container does not have:
#   - Elixir/OTP at the versions mix.exs pins
#   - PostgreSQL running, with the postgis and vector extensions available
#   - Hex dependencies fetched
#
# Until mix.exs exists this script is nearly a no-op, and says so.

set -uo pipefail

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '    ok: %s\n' "$*"; }
warn() { printf '    warning: %s\n' "$*"; }

say "FindMeAFlat cloud session setup"

# ---------------------------------------------------------------- repo shape
if [ ! -f mix.exs ]; then
  warn "No mix.exs at the repository root."
  warn "The Elixir application does not exist yet -- see"
  warn "docs/proposals/3-bet-go/001-elixir-multi-tenant-rewrite/PLAN.md"
  warn "Nothing to install. Exiting successfully."
  exit 0
fi
ok "mix.exs found"

# ------------------------------------------------------------- elixir + otp
say "Elixir toolchain"
if command -v elixir >/dev/null 2>&1; then
  ok "$(elixir --version | tail -1)"
else
  warn "elixir not on PATH."
  warn "Add it to the cloud environment image, or install it in the setup"
  warn "script before this one runs. This script does not install toolchains:"
  warn "a silent version drift between CI and cloud is worse than a hard stop."
  exit 1
fi

# The versions CI resolves, so a mismatch is visible rather than mysterious.
if [ -x .github/scripts/extract_versions.sh ]; then
  ./.github/scripts/extract_versions.sh || true
fi

# ----------------------------------------------------------------- postgres
say "PostgreSQL"
if command -v pg_isready >/dev/null 2>&1 && pg_isready -q 2>/dev/null; then
  ok "already accepting connections"
elif command -v pg_ctlcluster >/dev/null 2>&1; then
  cluster=$(find /etc/postgresql -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort -n | head -1)
  if [ -n "$cluster" ] && pg_ctlcluster "$cluster" main start 2>/dev/null; then
    ok "started cluster $cluster via pg_ctlcluster"
  else
    warn "could not start PostgreSQL via pg_ctlcluster"
  fi
elif command -v service >/dev/null 2>&1; then
  if service postgresql start >/dev/null 2>&1; then
    ok "started via service"
  else
    warn "could not start PostgreSQL via service"
  fi
else
  warn 'No PostgreSQL found. Ash/Ecto work and mix test will fail.'
  warn "Add postgres to the cloud environment, or run it as a service container."
fi

# postgis and vector are declared in the first migration even though Phase 1
# uses neither -- adding an extension to a live database later is a migration
# nobody enjoys. Check availability now so the failure surfaces at setup.
if command -v psql >/dev/null 2>&1 && pg_isready -q 2>/dev/null; then
  for ext in postgis vector; do
    if psql -U postgres -tAc \
        "select 1 from pg_available_extensions where name = '$ext'" 2>/dev/null | grep -q 1; then
      ok "extension available: $ext"
    else
      warn "extension NOT available: $ext (install postgresql-postgis / pgvector)"
    fi
  done
fi

# -------------------------------------------------------------- hex + deps
say "Dependencies"
mix local.hex --force --if-missing >/dev/null 2>&1 || true
mix local.rebar --force --if-missing >/dev/null 2>&1 || true

if mix deps.get; then
  ok "deps fetched"
else
  warn "mix deps.get failed."
  warn "Cloud environments default to Trusted network access; hex.pm must be"
  warn "reachable. Check the environment's network settings."
  exit 1
fi

# usage_rules regenerates the dependency link index the build skill reads.
if mix help usage_rules.sync >/dev/null 2>&1; then
  if mix usage_rules.sync --yes >/dev/null 2>&1; then
    ok "usage rules synced"
  else
    warn "usage_rules.sync failed (non-fatal)"
  fi
fi

say "Setup complete"
echo "    Verify with: mix ci"
