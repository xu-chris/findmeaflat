#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Elixir/Phoenix Worktree Setup (FindMeAFlat)
# Generates per-worktree config/.env.dev and config/.env.test with a unique
# database name and HTTP port so multiple git worktrees of the same app can run
# in parallel without colliding on DB or port.
#
# This project resolves dev/test config at RUNTIME, not compile time:
# config/runtime.exs loads config/.env.{dev,test} via Envy and reads
# DATABASE_URL + HTTP_PORT from the environment. So isolation happens at the
# env-var layer — we copy the main repo's real .env files (carrying every
# secret) and rewrite only the database name and port. We do NOT generate
# dev.local.exs/test.local.exs: nothing imports them here, and runtime.exs's
# `url: DATABASE_URL` would override them anyway.
#
# Database topology (docker-compose.yml): two SHARED Postgres servers.
#   find_me_a_flat_db       localhost:5432  -> all dev DBs  (find_me_a_flat_dev_<name>)
#   find_me_a_flat_test_db  localhost:5433  -> all test DBs (find_me_a_flat_test_<name>)
# Worktrees multiplex onto these two containers via distinct DB names. The test
# container is tmpfs (ephemeral): `docker compose restart` wipes worktree test
# DBs; re-run setup (or `mix test`) to recreate them.
#
# What it does on `setup`:
#   1. Reads app name from mix.exs, picks a random port in 9100-9999
#      (preserved across re-runs if config/.env.dev already exists).
#   2. Writes config/.env.dev  -> isolated DATABASE_URL + BASE_URL + HTTP_PORT.
#   3. Writes config/.env.test -> isolated DATABASE_URL (test endpoint is
#      server: false, so it needs no port).
#   4. Marks the tracked config/.env.test --assume-unchanged so the worktree's
#      git status stays clean.
#   5. Symlinks relative path: deps so they resolve from the worktree.
#   6. Preflight: verifies the Postgres containers are up (no auto-start), then
#      runs `mix deps.get && mix ecto.create && mix ecto.migrate` (dev DB). The
#      test DB is created on first `mix test` via the `test` mix alias.
#   7. Writes .claude/worktree.md so Claude Code picks up the right port.
#   8. Rewrites .claude/launch.json port (Claude Preview config) if present.
#   9. Registers a per-worktree tidewave MCP server at the worktree's port.
#  10. Initializes git submodules (worktrees don't check them out by default).
#
# Concurrent setup invocations (e.g. SessionStart hook + manual run) are
# serialized via a .claude/.worktree-setup.lock directory. Config files are
# written atomically (temp-file-and-rename).
#
# Prerequisite: the Postgres containers must be running before setup:
#   docker compose up -d
# Override container names with DEV_DB_CONTAINER / TEST_DB_CONTAINER, or set
# SKIP_DB_PREFLIGHT=1 if you run Postgres some other way.
# ------------------------------------------------------------

# Postgres containers from docker-compose.yml (container_name:). Dev DBs live in
# the first server, test DBs in the second.
DEV_DB_CONTAINER="${DEV_DB_CONTAINER:-find_me_a_flat_db}"
TEST_DB_CONTAINER="${TEST_DB_CONTAINER:-find_me_a_flat_test_db}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  setup [worktree-path] [worktree-name]  Generate .env overrides and set up database
  teardown [worktree-path]               Drop databases before worktree removal
  info [worktree-path]                   Show current worktree's database + port config

Options:
  worktree-path  Path to the worktree (default: current directory)
  worktree-name  Name for database/port derivation (default: directory basename).
                 Only used by setup — teardown reads the actual database names
                 back out of the worktree's config/.env.{dev,test}, so it needs
                 no name and can't drop the wrong database regardless of the
                 worktree's naming/path convention.

Examples:
  $(basename "$0") setup
  $(basename "$0") setup ../myapp.feature-auth feature-auth
  $(basename "$0") teardown ../myapp.feature-auth
  $(basename "$0") info
EOF
}

detect_app_name() {
  local dir="$1"
  # Extract app name from mix.exs. Use perl for cross-platform regex —
  # macOS BSD grep does not support -P (Perl-compatible regex).
  if [ -f "$dir/mix.exs" ]; then
    perl -ne 'print "$1\n" if /app:\s*:(\w+)/' "$dir/mix.exs" | head -1
  else
    echo "unknown"
  fi
}

random_port() {
  # Random port in range 9100-9999
  echo $(( RANDOM % 900 + 9100 ))
}

# Recover the HTTP port from an existing worktree config/.env.dev so re-runs
# preserve the port a session has already committed to memory,
# `.claude/launch.json`, and the tidewave MCP registration. Empty output ⇒
# caller picks a new port.
parse_port_from_env() {
  local env_file="$1"
  [ -f "$env_file" ] || return 0
  perl -ne 'print "$1\n" if /^HTTP_PORT=(\d+)/' "$env_file" | head -1
}

# Atomic file write: stream stdin into $1 via a sibling temp file, then rename.
atomic_write() {
  local target="$1"
  local tmp
  tmp="$(mktemp "${target}.XXXXXX")"
  if ! cat > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$target"
}

# Produce a worktree-isolated copy of a source .env file.
#   $1 src   $2 dest   $3 new database name   $4 new port (empty ⇒ leave ports)
# Swaps only the DATABASE_URL database-name segment (preserving credentials,
# host, port, and any query string). When a port is given, rewrites BASE_URL's
# port and ensures HTTP_PORT is set (the source files have no port key, so it is
# appended). Fails loudly if the source lacks a DATABASE_URL line — inventing
# one would create a mystery database.
generate_env_file() {
  local src="$1" dest="$2" new_db="$3" new_port="${4:-}"

  if [ ! -f "$src" ]; then
    echo "  ERROR: source env file not found: $src" >&2
    echo "  Run setup from a worktree of a repo whose main checkout has $(basename "$src")." >&2
    return 1
  fi
  if ! grep -q '^DATABASE_URL=' "$src"; then
    echo "  ERROR: $src has no DATABASE_URL line — cannot derive a worktree database." >&2
    return 1
  fi

  local tmp
  tmp="$(mktemp "${dest}.XXXXXX")"
  NEW_DB="$new_db" NEW_PORT="$new_port" perl -pe '
    # Replace the final /<dbname>[?query] on the DATABASE_URL line only.
    s{/[^/?\s]+(\?\S*)?(\s*)$}{/$ENV{NEW_DB}$1$2} if /^DATABASE_URL=/;
    # Repoint BASE_URL to the worktree port (dev only).
    s{^(BASE_URL=https?://[^:/\s]+):\d+}{$1:$ENV{NEW_PORT}} if length $ENV{NEW_PORT};
  ' "$src" > "$tmp"

  # The source .env files carry no HTTP_PORT/PORT key, so the worktree port has
  # to be appended (runtime.exs reads HTTP_PORT || PORT || 4000).
  if [ -n "$new_port" ]; then
    if grep -q '^HTTP_PORT=' "$tmp"; then
      perl -i -pe "s{^HTTP_PORT=.*}{HTTP_PORT=$new_port}" "$tmp"
    else
      printf 'HTTP_PORT=%s\n' "$new_port" >> "$tmp"
    fi

    # Disable LiveDebugger in worktrees: it binds a fixed port (4007), so parallel
    # dev servers would collide on it. runtime.exs reads this var.
    if grep -q '^LIVE_DEBUGGER_DISABLED=' "$tmp"; then
      perl -i -pe "s{^LIVE_DEBUGGER_DISABLED=.*}{LIVE_DEBUGGER_DISABLED=true}" "$tmp"
    else
      printf 'LIVE_DEBUGGER_DISABLED=true\n' >> "$tmp"
    fi
  fi

  mv "$tmp" "$dest"
}

# Verify the Postgres containers are reachable. We deliberately do NOT auto-start
# docker compose — a failed auto-start hides problems and makes setup harder to
# debug. Bypass with SKIP_DB_PREFLIGHT=1 if Postgres runs some other way.
ensure_postgres_up() {
  if [ -n "${SKIP_DB_PREFLIGHT:-}" ]; then
    return 0
  fi

  if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker not found, cannot verify Postgres." >&2
    echo "  Start the databases (docker compose up -d) or set SKIP_DB_PREFLIGHT=1." >&2
    return 1
  fi

  local ok=1
  for container in "$DEV_DB_CONTAINER" "$TEST_DB_CONTAINER"; do
    if ! docker exec "$container" pg_isready -U postgres -q >/dev/null 2>&1; then
      echo "ERROR: Postgres container '$container' is not reachable." >&2
      ok=0
    fi
  done

  if [ "$ok" -ne 1 ]; then
    echo "" >&2
    echo "Start the dev/test databases first:" >&2
    echo "  docker compose up -d" >&2
    echo "(or set SKIP_DB_PREFLIGHT=1 to bypass this check)" >&2
    return 1
  fi
}

sanitize_name() {
  # Convert worktree name to a safe database suffix
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_//;s/_$//'
}

link_beads_workspace() {
  local worktree_path="$1"
  local repo_root="$2"

  # Skip if this IS the main worktree (nothing to link).
  if [ "$worktree_path" = "$repo_root" ]; then
    return 0
  fi

  local main_beads="$repo_root/.beads"
  local worktree_beads="$worktree_path/.beads"
  local template="$repo_root/.beads.template"

  # Bootstrap main worktree's .beads/ from template if missing (fresh clone).
  if [ ! -d "$main_beads" ]; then
    if [ -d "$template" ]; then
      cp -R "$template" "$main_beads"
      echo "Bootstrapped $main_beads from .beads.template/"
    else
      echo "  Warning: $main_beads missing and no .beads.template/ to seed from"
      return 0
    fi
  fi

  # Replace a pre-existing regular .beads/ with a symlink to the main one.
  if [ -e "$worktree_beads" ] && [ ! -L "$worktree_beads" ]; then
    rm -rf "$worktree_beads"
  fi

  ln -sfn "$main_beads" "$worktree_beads"
  echo "Linked $worktree_beads -> $main_beads"
}

link_path_deps() {
  local worktree_path="$1"
  local mix_file="$worktree_path/mix.exs"

  if [ ! -f "$mix_file" ]; then
    return 0
  fi

  # Find the main repo root (not the linked worktree) to resolve relative path
  # deps correctly.
  local repo_root
  repo_root="$(git -C "$worktree_path" rev-parse --show-toplevel 2>/dev/null || true)"

  local git_common
  git_common="$(git -C "$worktree_path" rev-parse --git-common-dir 2>/dev/null || true)"
  if [ -n "$git_common" ] && [ "$git_common" != ".git" ]; then
    repo_root="$(cd "$worktree_path" && cd "$git_common" && cd .. && pwd)"
  fi

  if [ -z "$repo_root" ]; then
    return 0
  fi

  # Extract path deps from mix.exs (matches: path: "../something").
  local path_deps
  path_deps="$(perl -ne 'print "$1\n" while /path:\s*"([^"]+)"/g' "$mix_file" || true)"

  if [ -z "$path_deps" ]; then
    return 0
  fi

  echo "Linking path dependencies..."
  while IFS= read -r rel_path; do
    local abs_dep
    abs_dep="$(cd "$repo_root" && cd "$rel_path" 2>/dev/null && pwd || true)"

    if [ -z "$abs_dep" ] || [ ! -d "$abs_dep" ]; then
      echo "  Warning: path dep '$rel_path' not found at repo root, skipping"
      continue
    fi

    local worktree_resolved
    worktree_resolved="$(cd "$worktree_path" && cd "$rel_path" 2>/dev/null && pwd || true)"

    if [ "$worktree_resolved" = "$abs_dep" ]; then
      continue  # Already resolves correctly
    fi

    local link_target="$worktree_path/$rel_path"
    local link_parent
    link_parent="$(dirname "$link_target")"
    mkdir -p "$link_parent"

    if [ -e "$link_target" ]; then
      echo "  Skipping $rel_path (already exists)"
    else
      ln -s "$abs_dep" "$link_target"
      echo "  Linked $rel_path -> $abs_dep"
    fi
  done <<< "$path_deps"
}

# Resolve the main repo root for a worktree (falls back to the path itself).
resolve_repo_root() {
  local worktree_path="$1"
  local repo_root
  repo_root="$(git -C "$worktree_path" rev-parse --git-common-dir 2>/dev/null || true)"
  if [ -n "$repo_root" ] && [ "$repo_root" != ".git" ]; then
    (cd "$worktree_path" && cd "$repo_root" && cd .. && pwd)
  else
    echo "$worktree_path"
  fi
}

# Seed deps/ and _build/ from the main repo so the worktree compiles
# incrementally instead of cold. A cold build recompiles every dependency (the
# dominant cost for an Ash app — minutes); a seeded build only recompiles the
# source files that actually differ. Prefer APFS clonefile (cp -c): copy-on-write
# so it is near-instant and fully isolated from main (writes never touch the
# original). Fall back to hardlinks, then a plain copy. Skips a directory that
# already exists so re-runs don't clobber.
seed_build_artifacts() {
  local worktree_path="$1" repo_root="$2"
  [ "$worktree_path" = "$repo_root" ] && return 0

  local dir src dst
  for dir in deps _build; do
    src="$repo_root/$dir"
    dst="$worktree_path/$dir"
    [ -d "$src" ] || continue
    [ -e "$dst" ] && continue
    if cp -cR "$src" "$dst" 2>/dev/null; then
      echo "  Seeded $dir from main (copy-on-write clone)"
    elif cp -al "$src" "$dst" 2>/dev/null; then
      echo "  Seeded $dir from main (hardlinks)"
    elif cp -R "$src" "$dst" 2>/dev/null; then
      echo "  Seeded $dir from main (copy)"
    else
      echo "  Warning: could not seed $dir from main; a cold build will run"
    fi
  done
}

cmd_setup() {
  local worktree_path="${1:-.}"
  worktree_path="$(cd "$worktree_path" && pwd)"

  local worktree_name="${2:-$(basename "$worktree_path")}"
  local safe_name
  safe_name="$(sanitize_name "$worktree_name")"

  # Concurrency guard: mkdir is atomic on POSIX. A SessionStart hook and a manual
  # `setup` invocation could otherwise race and stomp each other's writes.
  local lock_dir="$worktree_path/.claude/.worktree-setup.lock"
  mkdir -p "$(dirname "$lock_dir")"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    echo "Another worktree setup is already running for $worktree_path; skipping." >&2
    return 0
  fi
  trap "rmdir '$lock_dir' 2>/dev/null || true" EXIT

  local app_name
  app_name="$(detect_app_name "$worktree_path")"

  local repo_root
  repo_root="$(resolve_repo_root "$worktree_path")"

  # Preserve an existing port across re-runs: Claude sessions, MCP registrations,
  # and browser tabs have already pinned to it.
  local port
  port="$(parse_port_from_env "$worktree_path/config/.env.dev")"
  [ -z "$port" ] && port="$(random_port)"

  local dev_db="${app_name}_dev_${safe_name}"
  local test_db="${app_name}_test_${safe_name}"

  echo "Elixir Worktree Setup"
  echo "  App:       $app_name"
  echo "  Worktree:  $worktree_name ($safe_name)"
  echo "  Dev DB:    $dev_db ($DEV_DB_CONTAINER)"
  echo "  Test DB:   $test_db ($TEST_DB_CONTAINER)"
  echo "  Dev Port:  $port"
  echo ""

  # Generate config/.env.dev — isolated database + port. Source is the main
  # repo's real .env.dev (carries all secrets); we swap only DB name and port.
  generate_env_file "$repo_root/config/.env.dev" "$worktree_path/config/.env.dev" "$dev_db" "$port"
  echo "Created config/.env.dev"

  # Generate config/.env.test — isolated database only (test endpoint is
  # server: false, so no port). .env.test is a tracked file, so mark it
  # assume-unchanged to keep the worktree's git status clean.
  generate_env_file "$repo_root/config/.env.test" "$worktree_path/config/.env.test" "$test_db" ""
  git -C "$worktree_path" update-index --assume-unchanged config/.env.test 2>/dev/null || true
  echo "Created config/.env.test"

  # Ensure the shared git hooks are worktree-aware. git_hooks auto_install is off
  # (see config/config.exs), so the worktree-aware hooks are installed here.
  # Idempotent; targets the shared hooks dir, so it covers every worktree + main.
  local hooks_installer
  hooks_installer="$(cd "$(dirname "$0")" && pwd)/install-git-hooks.sh"
  if [ -x "$hooks_installer" ]; then
    (cd "$worktree_path" && "$hooks_installer") || echo "  Warning: git hooks install failed" >&2
  fi

  # Symlink relative path deps (e.g. path: "../langchain") so they resolve from
  # the worktree rather than against the nested worktree path.
  link_path_deps "$worktree_path"

  # Share one canonical bead workspace across worktrees.
  link_beads_workspace "$worktree_path" "$repo_root"

  # Generate .claude/worktree.md for Claude context
  local claude_dir="$worktree_path/.claude"
  mkdir -p "$claude_dir"
  cat > "$claude_dir/worktree.md" <<WORKTREE_MD
# Worktree Context

This is an isolated git worktree, NOT the main repository.

- **Worktree name**: $worktree_name
- **Dev server port**: $port (NOT 4000)
- **Dev database**: $dev_db (container $DEV_DB_CONTAINER)
- **Test database**: $test_db (container $TEST_DB_CONTAINER)
- **Main repo**: $repo_root

When using Chrome DevTools or browser tools, navigate to \`http://localhost:$port\` (not 4000).
When referencing tidewave MCP, it runs on port $port.
WORKTREE_MD
  echo "Created $claude_dir/worktree.md"

  # Rewrite .claude/launch.json port so Claude Preview points at the worktree's
  # dev server instead of the main repo's default port.
  local launch_json="$worktree_path/.claude/launch.json"
  if [ -f "$launch_json" ] && command -v jq >/dev/null 2>&1; then
    local tmp
    tmp="$(mktemp)"
    if jq --argjson port "$port" '(.configurations[] | select(has("port")) | .port) = $port' \
        "$launch_json" > "$tmp"; then
      mv "$tmp" "$launch_json"
      echo "Updated $launch_json (port $port)"
      git -C "$worktree_path" update-index --assume-unchanged .claude/launch.json 2>/dev/null || true
    else
      rm -f "$tmp"
      echo "  Warning: could not update $launch_json — edit manually"
    fi
  fi

  # Register tidewave MCP server for this worktree's port via the patched
  # mcp-proxy (stdio transport), so Claude Code can attach at session start even
  # before the Phoenix dev server is running. Override the binary with
  # MCP_PROXY=/custom/path.
  MCP_PROXY="${MCP_PROXY:-$HOME/.local/bin/mcp-proxy}"
  if command -v claude >/dev/null 2>&1; then
    echo ""
    echo "Registering tidewave MCP server (port $port, via $MCP_PROXY)..."

    # Seed the tidewave tool catalog from the main repo's .mcp.json so a fresh
    # worktree has an offline-usable catalog on its first Claude session.
    local tidewave_seed=""
    if command -v jq >/dev/null 2>&1 && [ -f "$repo_root/.mcp.json" ]; then
      tidewave_seed="$(jq -r '
        .mcpServers.tidewave.args as $a
        | ($a | index("--tools")) as $i
        | if $i then $a[$i + 1] else empty end
      ' "$repo_root/.mcp.json" 2>/dev/null || true)"
    fi

    # Unset CLAUDECODE to avoid the env-var guard when called from within a
    # Claude session. The `--` separator before subprocess args is required so
    # `claude mcp add` does not consume `--tools` as its own option.
    (
      cd "$worktree_path"
      unset CLAUDECODE
      claude mcp remove --scope project tidewave >/dev/null 2>&1 || true
      if [ -n "$tidewave_seed" ]; then
        claude mcp add --scope project tidewave "$MCP_PROXY" -- \
          --tools "$tidewave_seed" \
          "http://localhost:${port}/tidewave/mcp"
      else
        claude mcp add --scope project tidewave "$MCP_PROXY" -- \
          "http://localhost:${port}/tidewave/mcp"
      fi
    ) || \
      echo "  Warning: could not register tidewave MCP — register manually with: claude mcp remove --scope project tidewave; claude mcp add --scope project tidewave $MCP_PROXY -- http://localhost:${port}/tidewave/mcp"
    git -C "$worktree_path" update-index --assume-unchanged .mcp.json 2>/dev/null || true
  fi

  # Initialize git submodules (worktrees don't auto-checkout submodules)
  if [ -f "$worktree_path/.gitmodules" ]; then
    echo ""
    echo "Initializing git submodules..."
    (cd "$worktree_path" && git submodule update --init --recursive)
  fi

  # Preflight the databases, then deps + dev database setup. The test DB is
  # created on first `mix test` (the `test` mix alias runs ecto.create).
  # Set WORKTREE_SKIP_DB=1 to provision config only (no deps/compile/DB) — useful
  # for fast iteration or CI where the database is provisioned separately.
  echo ""
  if [ -n "${WORKTREE_SKIP_DB:-}" ]; then
    echo "Skipping deps/compile/database setup (WORKTREE_SKIP_DB set)."
  else
    if ! ensure_postgres_up; then
      echo "" >&2
      echo "Config files are written; re-run setup once Postgres is up (the port is preserved)." >&2
      return 1
    fi

    # Warm the build from main so compilation is incremental, not cold.
    seed_build_artifacts "$worktree_path" "$repo_root"

    echo "Running database setup..."
    (cd "$worktree_path" && mix deps.get && mix ecto.setup )
  fi

  echo ""
  echo "Setup complete!"
  echo "  Dev server: cd $worktree_path && mix phx.server  (port $port)"
  echo "  Tests:      cd $worktree_path && mix test"
}

cmd_teardown() {
  local worktree_path="${1:-.}"
  worktree_path="$(cd "$worktree_path" && pwd)"

  if [ ! -f "$worktree_path/config/.env.dev" ] && [ ! -f "$worktree_path/config/.env.test" ]; then
    echo "No worktree .env overrides found — nothing to tear down."
    return 0
  fi

  # Read the actual database names back out of the generated .env files rather
  # than re-deriving them from a worktree/branch name: the caller's naming
  # convention (directory basename, branch name, ...) isn't guaranteed to match
  # what setup used, and the .env files are the source of truth for what setup
  # actually created.
  local dev_db test_db
  dev_db="$(perl -ne 'print "$1\n" if m{/([A-Za-z0-9_]+)(\?|\s*$)}' <(grep '^DATABASE_URL=' "$worktree_path/config/.env.dev" 2>/dev/null) | head -1)"
  test_db="$(perl -ne 'print "$1\n" if m{/([A-Za-z0-9_]+)(\?|\s*$)}' <(grep '^DATABASE_URL=' "$worktree_path/config/.env.test" 2>/dev/null) | head -1)"

  echo "Dropping databases for worktree at $worktree_path..."
  # Drop directly in the containers (no mix, no MIX_ENV juggling). `|| true` so a
  # stopped container or absent DB never blocks worktree removal.
  if [ -z "$dev_db" ] && [ -z "$test_db" ]; then
    echo "  Warning: could not parse database names from config/.env.{dev,test} — nothing dropped."
  elif command -v docker >/dev/null 2>&1; then
    [ -n "$dev_db" ] && { docker exec "$DEV_DB_CONTAINER" dropdb -U postgres --if-exists "$dev_db" 2>/dev/null || true; }
    [ -n "$test_db" ] && { docker exec "$TEST_DB_CONTAINER" dropdb -U postgres --if-exists "$test_db" 2>/dev/null || true; }
    echo "  Dropped $dev_db and $test_db (if they existed)"
  else
    echo "  Warning: docker not found — drop $dev_db / $test_db manually."
  fi

  # Stop tracking the assume-unchanged test env file, then remove the worktree
  # overrides and context.
  git -C "$worktree_path" update-index --no-assume-unchanged config/.env.test 2>/dev/null || true
  rm -f "$worktree_path/config/.env.dev"
  rm -f "$worktree_path/config/.env.test"
  git -C "$worktree_path" checkout -- config/.env.test 2>/dev/null || true
  rm -f "$worktree_path/.claude/worktree.md"

  echo "Teardown complete. Worktree .env overrides removed."
}

cmd_info() {
  local worktree_path="${1:-.}"
  worktree_path="$(cd "$worktree_path" && pwd)"

  echo "Worktree: $(basename "$worktree_path")"
  echo "Path:     $worktree_path"
  echo ""

  # Show only the database name and port, never the full .env (it holds secrets).
  if [ -f "$worktree_path/config/.env.dev" ]; then
    echo "--- dev ---"
    echo "  Database: $(perl -ne 'print "$1\n" if m{/([A-Za-z0-9_]+)(\?|\s*$)}' <(grep '^DATABASE_URL=' "$worktree_path/config/.env.dev") | head -1)"
    echo "  HTTP port: $(parse_port_from_env "$worktree_path/config/.env.dev")"
  else
    echo "No config/.env.dev found (worktree not set up)"
  fi

  if [ -f "$worktree_path/config/.env.test" ]; then
    echo "--- test ---"
    echo "  Database: $(perl -ne 'print "$1\n" if m{/([A-Za-z0-9_]+)(\?|\s*$)}' <(grep '^DATABASE_URL=' "$worktree_path/config/.env.test") | head -1)"
  else
    echo "No config/.env.test found (worktree not set up)"
  fi
}

# Main dispatch
case "${1:-help}" in
  setup)
    shift
    cmd_setup "$@"
    ;;
  teardown)
    shift
    cmd_teardown "$@"
    ;;
  info)
    shift
    cmd_info "$@"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo "Unknown command: $1" >&2
    usage
    exit 1
    ;;
esac
