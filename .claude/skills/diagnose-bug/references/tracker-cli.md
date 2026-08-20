# Tracker CLI Gotchas

**GitHub Issues via `gh` is the only tracker.** No Basecamp, no Linear, no Jira — the
`basecamp` CLI is not installed and is not allowlisted. Mechanics, epics and sub-issues:
[../../../../docs/agents/issue-tracker.md](../../../../docs/agents/issue-tracker.md).

Reading is unrestricted. Posting a comment, opening an issue, or applying a label is an
external effect on a **public repository** and needs explicit authority.

## `gh` gotchas

- `gh issue list --json` may prepend warnings to its output. Extract from the first JSON
  `[` or `{` before parsing rather than piping the whole stream into `jq`.
- Sub-issue and dependency endpoints key on the **internal issue `id`**, not the display
  number. Fetch it first: `gh api repos/xu-chris/findmeaflat/issues/<n> --jq '.id'`.
- `gh issue create --label` fails the whole call if any label does not exist. `afk`,
  `epic`, `security` and `legal` **do not exist in this repository yet** — see
  [triage-labels.md](../../../../docs/agents/triage-labels.md) for the create commands.
- For multiline bodies use `--body-file -` and pipe, or `$'...'`. A double-quoted `\n`
  stays literal, and backticks in a double-quoted body run command substitution.
- `gh run view <id> --log-failed` is far cheaper than `--log` when triaging CI.
- `gh api` paginates at 30 by default; pass `--paginate` when counting anything.

## Repository-specific

- The repository is **public**. Never put an absolute home path, a token, a chat ID, or
  a Telegram bot token in an issue body or comment.
- `conf/config.json` holds the bot token and is gitignored. If a traceback or log
  excerpt would include it, redact before posting.
- Portal-breakage issues have a required shape — status, response size, which selectors
  matched and which returned zero. See
  [issue-tracker.md](../../../../docs/agents/issue-tracker.md).
