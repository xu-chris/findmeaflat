# Pull Requests

## Opening one

Title follows the commit convention. The body states what changed and why, what verified it, and anything deliberately left out.

Link the proposal card (`docs/proposals/<lane>/NNN-slug/`) and the issue. Follow `.github/PULL_REQUEST_TEMPLATE/` when a template fits.

```bash
gh pr create --title "type: outcome" --body-file <path>
gh pr create --template dripfeed.md   # craft cleanup
```

**An agent-opened PR ends at "tests green, rationale written". Never merge it.**

## External review thread

After a Codex review, post the synthesis as a PR comment **including the thread id** — without it, a later session cannot continue the thread and repeats the whole independence round at full cost.

## Answering incoming review comments

```bash
gh pr view <n> --comments
gh pr diff <n>
```

Address each comment on its own terms. Where you disagree, say so on the PR with the reason rather than silently skipping it — an unanswered comment reads as ignored.

`review-and-ship` owns judging the comment; this file covers the `gh` mechanics. Report the follow-up commits and the exact push command; push only on a separate grant. Once pushed, reply pointing at the commit that resolves each thread, and react 👍 or 👎 to every external review comment as well as replying.

## Labels

Verify with `gh label list` before applying anything. **`afk` is the only label that drives automation** — an agent may pick this up and run it unattended, and applying it **is** the approval. Its absence always means human in the loop. Full list: [triage-labels.md](../../../../docs/agents/triage-labels.md).
