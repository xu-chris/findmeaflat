# Issue Tracker

**GitHub Issues on `xu-chris/findmeaflat`**, driven through `gh`. There is no external
tracker — no Basecamp, no Linear, no Jira. Anything in a skill implying otherwise is
leftover from the harness this was adapted from; report it.

The repository is **public**, so issue bodies are world-readable. No tokens, no absolute
home paths, no personal data in an issue.

## Epics and sub-issues

GitHub native sub-issues are enabled on this repository.

One `epic` parent per PLAN, one sub-issue per vertical slice. Attach each sub-issue to
the epic and record blockers as native GitHub dependencies. Both are keyed on the
**internal issue `id`**, not the number you see in the UI:

```bash
# internal id for issue #42
gh api repos/xu-chris/findmeaflat/issues/42 --jq '.id'

# attach a sub-issue to its epic
gh api -X POST repos/xu-chris/findmeaflat/issues/<epic#>/sub_issues \
  -F sub_issue_id=<internal id>

# list an epic's sub-issues
gh api repos/xu-chris/findmeaflat/issues/<epic#>/sub_issues --jq '.[].number'
```

Link the proposal card and the epic bidirectionally: the epic body links
`docs/proposals/3-bet-go/NNN-slug/PLAN.md`, and the PLAN links the epic URL.

## What goes in a body

**Behaviour and acceptance criteria, then a link to the PLAN slice for the rest.**

File paths and code go stale on a tracker while `PLAN.md` moves with the code, so paths
stay in the plan. The one exception is a snippet pinning a decision more precisely than
prose can — a schema, a state machine, a type shape — trimmed to the decision.

For a bug, the body carries the reproduction command, root cause, evidence, complexity
verdict with its reason, and the smallest recommended repair.

## Portal-breakage issues specifically

This repository's recurring bug is a portal changing its markup. Such an issue must
carry, or it is not actionable:

- The portal and the exact URL probed
- HTTP status and response size
- Which selectors matched and which returned zero — the counts, not "it broke"
- Whether the response was a bot challenge, a 410, or valid HTML that no longer matches

Issue #20 (*Immowelt pagination does not work*, open since 2022-07-24) is the worked
example of what happens without this: three years open because nobody recorded that the
next-page control is a `<button>` with no `href`, which makes it unfixable in the
current stack rather than merely broken.

## Labels

See [triage-labels.md](triage-labels.md). `afk` is the only label that grants authority,
and its absence always means human in the loop.
