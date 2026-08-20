# Claude Code on the Web

Cloud sessions for this repository — what is configured here, and the three
steps only you can do.

## Steps only you can do

These are interactive or account-level. They cannot be scripted from a session.

**1. Connect GitHub.** Either route works:

- **`/web-setup`** in an interactive `claude` terminal, which syncs your local
  `gh` CLI token to your Claude account. **Your `gh` is already authenticated**
  as `xu-chris` with `repo`, `workflow`, `read:org` and `gist` scopes, so this
  is the shorter path.
- **The Claude GitHub App**, authorised during web onboarding at
  [claude.ai/code](https://claude.ai/code).

They are not equivalent for one thing: **Auto-fix needs the GitHub App.** The
`/web-setup` token grants repository access, but PR webhooks — the mechanism
that lets Claude react to a failed check or a review comment — require the App
installed on `xu-chris/findmeaflat`. Install it at
[github.com/apps/claude](https://github.com/apps/claude) if you want that.

Note what App installation is *not*: it is not access control. A cloud session
can reach any repository the connected account can see, installed or not.

**2. Point the cloud environment's setup script at this repo.** In the
environment configuration, set the setup script to:

```bash
bash .github/scripts/cloud-setup.sh
```

**3. Check network access.** Environments default to **Trusted**. This project
needs more than most:

| Host | Why |
|---|---|
| `hex.pm`, `repo.hex.pm` | `mix deps.get` |
| `github.com` | clone, push |
| `gdi.berlin.de`, `daten.berlin.de` | Berlin Wohnlagen / Umweltatlas WFS |
| `open-data.dortmund.de` | Dortmund Mietspiegel API |
| `overpass-api.de` | OpenStreetMap building data |
| the six portals | only if a session runs a live probe |

**Do not grant the portals by default.** A cloud session crawling
kleinanzeigen.de from Anthropic-managed infrastructure puts requests on shared
egress IPs that other people also use. Fixture-based tests need no network, and
`CRAWL-DIAGNOSIS.md` already records what live probes return — prefer both over
re-probing from a cloud VM.

## What is configured in the repository

Cloud sessions read the repo, so most of the harness works without setup:

| Thing | Where | Works in cloud |
|---|---|---|
| Skills | `.claude/skills/` | yes |
| Subagents | `.claude/agents/` | yes, picked up automatically |
| Settings | `.claude/settings.json` | yes |
| Setup script | `.github/scripts/cloud-setup.sh` | once pointed at (step 2) |
| Local permissions | `.claude/settings.local.json` | **no — gitignored, by design** |

**Two things behave differently in a cloud session**, both from
`.claude/settings.json`:

- The `Stop` hook asks for `mix ci`. Until `mix.exs` exists it correctly
  answers "no Elixir project"; after that it needs the toolchain the setup
  script checks for.
- `mcp__tidewave__*` permissions have nothing to attach to. Tidewave needs a
  running Phoenix server. Expect those tools to fail, and do not debug it.

To change settings for a cloud session, use the environment's variables or
commit to `.claude/settings.json`. `/config` on the web opens your account
settings rather than setting a repository value.

## Useful flows

```bash
# start a cloud session for this repo, from a local checkout
claude --cloud "Implement slice S3 from the PLAN"

# several at once — each is its own session
claude --cloud "Implement S4"
claude --cloud "Implement S5"

# queue a follow-up into a running session, from any machine
claude -p "also add the fixture for immowelt" --cloud session_01ABC...

# pull a cloud session into this terminal, with its branch and history
claude --teleport
```

**The cloud VM clones your GitHub remote at your current branch, not your local
checkout.** Push before starting a session, or the session works from stale
code. This bites hardest when you have just written a plan and not pushed it.

The plan-then-execute split suits this project: shape the slice locally in plan
mode, push, then hand the mechanical part to a cloud session. Slices in
`PLAN.md` marked **AFK** are the ones sized for that.

## Caveats worth knowing before you rely on it

- **Rate limits are shared** with all your other Claude usage. Three parallel
  cloud sessions consume roughly three times the budget.
- **Sessions expire** after inactivity and the VM is reclaimed. Reopening from
  claude.ai restores the conversation on a fresh VM.
- **Teleport needs a clean working tree**, the same repository (not a fork),
  the branch pushed, and the same claude.ai account.
- **Auto-fix can reply to PR threads as you.** Replies are labelled as coming
  from Claude Code, but they post under your GitHub account. This repository
  has no comment-triggered automation, so the deploy-on-comment hazard the docs
  warn about does not apply here.
