# Claude Code on the Web

What to configure in the cloud environment UI at [claude.ai/code](https://claude.ai/code),
and what the repository already handles.

## The two-part design, and why

A cloud environment is built once and snapshotted, then each session starts from
that snapshot. **The snapshot keeps files, never processes.** So the work splits:

| | Runs | Job |
|---|---|---|
| **Setup script** — `.agents/cloud/setup-script.sh` | once, as root, before Claude Code starts, only when no environment cache exists | *install* Erlang/OTP, Elixir, PostgreSQL |
| **SessionStart hook** — `.agents/hooks/cloud-container-setup.sh` | every session | *start* PostgreSQL, report what is and is not working |

Getting this backwards is the common failure: a setup script that starts the
database appears to work, then every later session has an installed-but-stopped
cluster and no explanation.

**A non-zero exit from the setup script fails session start with no
diagnostics.** The script therefore always exits 0, records everything in
`/var/log/findmeaflat-cloud-setup.log`, and writes a status file the hook reads
back. A degraded environment that says why beats a dead one that doesn't.

## Configure the environment

**1. Setup script.** Copy the contents of
[`.agents/cloud/setup-script.sh`](../../.agents/cloud/setup-script.sh) into the
environment's **Setup script** field.

Paste the contents — do not reference the path. The environment is not tied to
one repository and the script runs before any working copy exists, so it reads
nothing from the repo. That is also why the version pins are duplicated inside
it and **must stay in sync with `.tool-versions`** (`erlang 28.5`,
`elixir 1.20.1-otp-28`).

**2. Network access.** Setup cannot complete on the default allowlist. Required:

| Host | Needed for |
|---|---|
| `builds.hex.pm` | precompiled Erlang/OTP and Elixir |
| `apt.postgresql.org` | PGDG PostgreSQL 18, postgis, pgvector |
| `repo.hex.pm`, `hex.pm` | `mix deps.get` |
| `github.com` | clone, push |

Optional, and only for enrichment work later: `gdi.berlin.de`,
`daten.berlin.de`, `open-data.dortmund.de`, `overpass-api.de`.

**Do not allow the six portals.** A cloud session crawling kleinanzeigen.de runs
from shared Anthropic egress IPs that other people also use. Fixture-based tests
need no network, and `CRAWL-DIAGNOSIS.md` already records what live probes
return — prefer both over re-probing from a cloud VM.

**3. Connect GitHub.** Either route works:

- **`/web-setup`** in an interactive `claude` terminal, syncing your local `gh`
  token. Your `gh` is already authenticated as `xu-chris` with `repo`,
  `workflow`, `read:org` and `gist`, so this is the shorter path.
- **The Claude GitHub App**, authorised during web onboarding.

They differ in one way: **Auto-fix needs the App.** The `/web-setup` token
grants repository access, but the PR webhooks that let Claude react to a failed
check or a review comment require the App installed on `xu-chris/findmeaflat`.

App installation is not access control. A session can reach any repository the
connected account can see, installed or not.

## What the setup script installs

- **Erlang/OTP 28.5** and **Elixir 1.20.1-otp-28** from `builds.hex.pm`,
  precompiled for the same Ubuntu 24.04 the VM runs — no source build. The
  published OTP reference can carry a patch suffix the pin does not
  (`OTP-28.5.0.2` for `erlang 28.5`), so it resolves from the build index rather
  than guessing a filename.
- **PostgreSQL 18** from PGDG on port **5433**, matching `ci.yml`. Credentials
  `postgres` / `postgres`. The base image's own cluster on 5432 is left alone.
- **postgis** and **pgvector**, best-effort. The first migration enables both
  even though Phase 1 uses neither, because adding an extension to a live
  database later is a migration nobody enjoys. If a package is unavailable the
  script logs it and continues, and the SessionStart hook repeats the warning —
  otherwise the gap surfaces weeks later as a migration error that reads like a
  code bug.
- **UTF-8 encoding with an explicit `C.UTF-8` locale.** Without it `initdb`
  inherits the container's POSIX locale and lands on `SQL_ASCII`, which would
  corrupt exactly this project's primary data: German listing titles and street
  names like *Müllerstraße*, *Schöneberg*, *Prenzlauer Allee*.
- `fsync = off` and friends. The VM is ephemeral; durability buys nothing.

## What the repository already handles

Cloud sessions read the repo, so most of the harness works untouched:

| Thing | Where | Works in cloud |
|---|---|---|
| Skills | `.claude/skills/` | yes |
| Subagents | `.claude/agents/` | yes, picked up automatically |
| Settings and hooks | `.claude/settings.json` | yes |
| Local permissions | `.claude/settings.local.json` | **no — gitignored, by design** |

One thing behaves differently: `mcp__tidewave__*` permissions have nothing to
attach to until a Phoenix server is running. Expect those tools to fail; do not
debug it.

To change settings for a cloud session, use the environment's variables or
commit to `.claude/settings.json`. `/config` on the web opens your account
settings rather than setting a repository value.

## Useful flows

```bash
claude --cloud "Implement slice S3 from the PLAN"
claude -p "also add the immowelt fixture" --cloud session_01ABC...
claude --teleport
```

**The cloud VM clones your GitHub remote at your current branch, not your local
checkout.** Push before starting a session, or it works from stale code. This
bites hardest right after writing a plan you have not pushed.

Slices in `PLAN.md` marked **AFK** are the ones sized to hand to a cloud session.

## Caveats

- **Rate limits are shared** with all your other Claude usage. Three parallel
  sessions cost roughly three times the budget.
- **Sessions expire** after inactivity and the VM is reclaimed; reopening
  restores the conversation on a fresh VM, which re-runs the SessionStart hook
  but not the setup script.
- **Teleport needs** a clean working tree, the same repository (not a fork), the
  branch pushed, and the same claude.ai account.
- **Auto-fix can reply to PR threads under your GitHub account**, labelled as
  Claude Code. This repository has no comment-triggered automation, so the
  deploy-on-comment hazard the docs warn about does not apply here.
