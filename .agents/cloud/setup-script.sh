#!/usr/bin/env bash
# Cloud environment setup script for FindMeAFlat.
#
# PASTE THE CONTENTS OF THIS FILE into the "Setup script" field of the cloud
# environment at claude.ai/code. It is NOT invoked from the repository: the
# environment is not tied to one repo, and this runs before any working copy
# exists.
#
# What it does: installs Erlang/OTP, Elixir and PostgreSQL on the session VM,
# none of which the base image carries at the versions this project pins.
#
# Three constraints shape it:
#
#   1. It runs before Claude Code starts, as root, and only when no environment
#      cache exists. Anthropic snapshots the filesystem afterwards, so what the
#      script writes to disk carries into later sessions and what it leaves
#      running does not. Starting services belongs in the SessionStart hook
#      (.agents/hooks/cloud-container-setup.sh), not here.
#   2. The environment is not tied to one repository, so the script assumes the
#      working copy is absent and reads nothing from it. Version pins are
#      duplicated below and must stay in sync with .tool-versions.
#   3. A non-zero exit fails session start with no diagnostics. The script
#      therefore always exits 0 and records what happened in
#      /var/log/findmeaflat-cloud-setup.log, which the SessionStart hook reads
#      back and reports.

set -uo pipefail

# Keep in sync with .tool-versions (elixir 1.20.1-otp-28, erlang 28.5).
OTP_VERSION="${FINDMEAFLAT_OTP_VERSION:-28.5}"
ELIXIR_VERSION="${FINDMEAFLAT_ELIXIR_VERSION:-1.20.1}"
# PostgreSQL 18 matches .github/workflows/ci.yml.
PG_VERSION="${FINDMEAFLAT_PG_VERSION:-18}"
# 5433 is the port ci.yml's service container and the worktree hook use.
PG_PORT="${FINDMEAFLAT_PG_PORT:-5433}"

OTP_MAJOR="${OTP_VERSION%%.*}"
BUILDS="https://builds.hex.pm/builds"
# builds.hex.pm publishes amd64 with no architecture segment; only non-amd64
# targets carry one (arm64/ubuntu-24.04). "x86_64/ubuntu-24.04" returns 404.
OTP_TARGET="${FINDMEAFLAT_OTP_TARGET:-ubuntu-24.04}"
OTP_ROOT=/usr/local/otp
ELIXIR_ROOT=/usr/local/elixir
STATE_DIR=/usr/local/share/findmeaflat-cloud
LOG=/var/log/findmeaflat-cloud-setup.log

export DEBIAN_FRONTEND=noninteractive

mkdir -p "$STATE_DIR"
: >"$LOG"

log() { printf '[setup] %s\n' "$*" | tee -a "$LOG"; }
fail() { printf '[setup] FAILED: %s\n' "$*" | tee -a "$LOG"; }

# The base image carries third-party PPAs the egress proxy answers with 403. On
# a fresh container apt reports those as errors and exits non-zero even though
# the Ubuntu archives fetched fine, so treating update as fatal loses every
# package below it. The install calls are the real gate.
apt_update() {
  apt-get update -qq >>"$LOG" 2>&1 ||
    log "apt-get update reported errors (blocked third-party PPAs); continuing"
}

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------
install_system_packages() {
  log "installing system packages"
  apt_update
  # ca-certificates stays out on purpose: the base image has it, and
  # reinstalling rebuilds a trust store that already holds the session proxy CA.
  apt-get install -y -qq --no-install-recommends \
    libssl3t64 libncurses6 libodbc2 libsctp1 unzip inotify-tools \
    >>"$LOG" 2>&1 || { fail "apt-get install"; return 1; }
}

# ---------------------------------------------------------------------------
# Erlang/OTP
# ---------------------------------------------------------------------------
# builds.hex.pm publishes OTP compiled on the same Ubuntu 24.04 the session VM
# runs, so the tarball drops in without a source build. The published reference
# can carry a patch suffix the pin does not (OTP-28.5.0.2 for erlang 28.5), so
# resolve from the build index rather than guessing the filename.
resolve_otp_ref() {
  local index escaped
  # Exit 2 separates "cannot fetch the index" from "the index has no such
  # version". The first is a wrong OTP_TARGET or a blocked host, the second a
  # wrong pin. They need different fixes.
  index="$(curl -fsS --max-time 60 "$BUILDS/otp/$OTP_TARGET/builds.txt")" || return 2
  escaped="${OTP_VERSION//./\\.}"

  if printf '%s\n' "$index" | awk '{print $1}' | grep -qxE "OTP-$escaped"; then
    printf 'OTP-%s\n' "$OTP_VERSION"
    return 0
  fi
  printf '%s\n' "$index" | awk '{print $1}' \
    | grep -E "^OTP-$escaped(\.[0-9]+)*$" | sort -V | tail -1 | grep . || return 1
}

install_otp() {
  local ref url tmp rc code
  ref="$(resolve_otp_ref)"
  rc=$?
  if [ "$rc" -eq 2 ]; then
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 60 "$BUILDS/otp/$OTP_TARGET/builds.txt" 2>/dev/null)"
    case "$code" in
      404) fail "$BUILDS/otp/$OTP_TARGET/builds.txt returned 404 — OTP_TARGET '$OTP_TARGET' is wrong for this architecture" ;;
      000 | "") fail "cannot reach $BUILDS/otp/$OTP_TARGET/builds.txt — allow builds.hex.pm in the environment's network settings" ;;
      *) fail "$BUILDS/otp/$OTP_TARGET/builds.txt returned HTTP $code" ;;
    esac
    return 1
  elif [ "$rc" -ne 0 ]; then
    fail "no OTP build for $OTP_VERSION on $OTP_TARGET"
    return 1
  fi
  url="$BUILDS/otp/$OTP_TARGET/$ref.tar.gz"
  log "installing Erlang/OTP $ref"

  tmp="$(mktemp -d)"
  curl -fsS --max-time 300 "$url" -o "$tmp/otp.tar.gz" >>"$LOG" 2>&1 \
    || { fail "download $url"; rm -rf "$tmp"; return 1; }

  rm -rf "$OTP_ROOT"
  mkdir -p "$OTP_ROOT"
  # The tarball wraps everything in one directory; strip it so Install runs
  # against the prefix it is given.
  tar -xzf "$tmp/otp.tar.gz" -C "$OTP_ROOT" --strip-components=1 \
    || { fail "extract OTP"; rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"

  # A relocated OTP has to be told its own prefix before erl works.
  (cd "$OTP_ROOT" && ./Install -minimal "$OTP_ROOT") >>"$LOG" 2>&1 \
    || { fail "OTP Install"; return 1; }

  local bin
  for bin in erl erlc escript dialyzer typer ct_run epmd run_erl to_erl; do
    [ -x "$OTP_ROOT/bin/$bin" ] && ln -sf "$OTP_ROOT/bin/$bin" "/usr/local/bin/$bin"
  done

  printf '%s\n' "$ref" >"$STATE_DIR/otp-ref"
  erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().' >>"$LOG" 2>&1 \
    || { fail "erl does not run"; return 1; }
}

# ---------------------------------------------------------------------------
# Elixir
# ---------------------------------------------------------------------------
install_elixir() {
  local ref url tmp
  ref="v$ELIXIR_VERSION-otp-$OTP_MAJOR"
  url="$BUILDS/elixir/$ref.zip"
  log "installing Elixir $ref"

  tmp="$(mktemp -d)"
  curl -fsS --max-time 300 "$url" -o "$tmp/elixir.zip" >>"$LOG" 2>&1 \
    || { fail "download $url — allow builds.hex.pm, or check this Elixir/OTP pair is published"; rm -rf "$tmp"; return 1; }

  rm -rf "$ELIXIR_ROOT"
  mkdir -p "$ELIXIR_ROOT"
  unzip -q "$tmp/elixir.zip" -d "$ELIXIR_ROOT" \
    || { fail "extract Elixir"; rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"

  local bin
  for bin in elixir elixirc mix iex; do
    ln -sf "$ELIXIR_ROOT/bin/$bin" "/usr/local/bin/$bin"
  done

  printf '%s\n' "$ref" >"$STATE_DIR/elixir-ref"
  elixir --version >>"$LOG" 2>&1 || { fail "elixir does not run"; return 1; }

  # Install Hex and rebar now so the snapshot carries them and no session pays
  # for it. Both land under $MIX_HOME, which defaults to /root/.mix.
  mix local.hex --force >>"$LOG" 2>&1 || fail "mix local.hex"
  mix local.rebar --force >>"$LOG" 2>&1 || fail "mix local.rebar"
}

# ---------------------------------------------------------------------------
# PostgreSQL
# ---------------------------------------------------------------------------
# The base image's cluster stays untouched on 5432. This adds a PGDG cluster on
# 5433 with the credentials and fsync-off tuning ci.yml already assumes.
install_postgres() {
  log "installing PostgreSQL $PG_VERSION"

  install -d /usr/share/postgresql-common/pgdg
  # Fetch the signing key from apt.postgresql.org rather than the main site so
  # the environment allowlist needs one host instead of two.
  curl -fsS --max-time 60 https://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc \
    -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc >>"$LOG" 2>&1 \
    || { fail "download PGDG signing key — allow apt.postgresql.org in the environment's network settings"; return 1; }

  printf 'deb [signed-by=%s] %s %s-pgdg main\n' \
    /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    https://apt.postgresql.org/pub/repos/apt \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" \
    >/etc/apt/sources.list.d/pgdg.list

  apt_update
  apt-get install -y -qq "postgresql-$PG_VERSION" >>"$LOG" 2>&1 \
    || { fail "apt-get install postgresql-$PG_VERSION"; return 1; }

  # postgis and vector are enabled in the first migration even though Phase 1
  # uses neither: adding an extension to a live database later is a migration
  # nobody enjoys. Best-effort — a missing package must not fail setup, but the
  # log has to say so, because the failure would otherwise surface as a
  # confusing migration error weeks later.
  for ext_pkg in "postgresql-$PG_VERSION-postgis-3" "postgresql-$PG_VERSION-pgvector"; do
    if apt-get install -y -qq "$ext_pkg" >>"$LOG" 2>&1; then
      log "installed $ext_pkg"
    else
      fail "$ext_pkg unavailable — the extension will not be creatable in migrations"
    fi
  done

  # The package picks the first free port. Recreate the cluster so the port is
  # the one the project's configuration expects, not whatever was free.
  #
  # Encoding and locale are explicit because initdb otherwise inherits the
  # container's POSIX locale and lands on SQL_ASCII. This project stores German
  # listing titles and street names — Müllerstraße, Schöneberg, Prenzlauer
  # Allee — so SQL_ASCII would corrupt the primary data.
  pg_dropcluster "$PG_VERSION" main --stop >>"$LOG" 2>&1 || true
  pg_createcluster "$PG_VERSION" main -p "$PG_PORT" --encoding UTF8 --locale C.UTF-8 >>"$LOG" 2>&1 \
    || { fail "pg_createcluster"; return 1; }

  # Ephemeral cloud VM: durability buys nothing, so trade it for speed. Same
  # switches ci.yml applies to its service container.
  cat >"/etc/postgresql/$PG_VERSION/main/conf.d/findmeaflat.conf" <<'CONF'
# Written by the cloud environment setup script. Ephemeral cloud VM: durability
# buys nothing here, so the cluster runs with the same switches CI applies.
fsync = off
synchronous_commit = off
full_page_writes = off
max_connections = 500
idle_in_transaction_session_timeout = 120000
CONF

  # Ecto connects over TCP to 127.0.0.1 with a password, so scram has to be
  # allowed for host connections before the role gets one.
  local hba="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"
  {
    printf '\n# Written by the cloud environment setup script — local development only.\n'
    printf 'host    all             all             127.0.0.1/32            scram-sha-256\n'
    printf 'host    all             all             ::1/128                 scram-sha-256\n'
  } >>"$hba"

  pg_ctlcluster "$PG_VERSION" main start >>"$LOG" 2>&1 \
    || { fail "start cluster for role setup"; return 1; }
  su postgres -c "psql -p $PG_PORT -c \"ALTER USER postgres PASSWORD 'postgres'\"" >>"$LOG" 2>&1 \
    || fail "set postgres password"
  # Leave the cluster stopped: the snapshot keeps files, never processes, and
  # the SessionStart hook starts it per session anyway.
  pg_ctlcluster "$PG_VERSION" main stop >>"$LOG" 2>&1 || true
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
status=ok

install_system_packages || status=degraded
install_otp || status=degraded
install_elixir || status=degraded
install_postgres || status=degraded

# The SessionStart hook reads this file to learn where things landed and
# whether to warn. Keep the keys stable.
cat >"$STATE_DIR/env" <<ENV
FINDMEAFLAT_SETUP_STATUS=$status
FINDMEAFLAT_PG_VERSION=$PG_VERSION
FINDMEAFLAT_PG_PORT=$PG_PORT
FINDMEAFLAT_OTP_VERSION=$OTP_VERSION
FINDMEAFLAT_ELIXIR_VERSION=$ELIXIR_VERSION
ENV

log "setup finished: $status"
exit 0
