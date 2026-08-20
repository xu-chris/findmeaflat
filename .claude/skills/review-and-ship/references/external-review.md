# External Review — Codex

An outside expert catches what an anchored view cannot. Mechanics adapted from Basecamp's `consult-outside-expert`.

## The rule that makes it worth doing

> **An expert is not a judge. An expert is a signal generator. The mediator owns synthesis and decisions.**

Codex output is evidence to weigh, never instruction to follow. When Codex and the internal review disagree, steelman both and put it to Chris — never adopt the outsider's view for being the outsider's.

## Independence protocol

**Round 1: Codex sees the frozen artifact and the governing rules. Nothing else.** Not the internal findings, the self-review, the reasoning, or the plan's rationale. An anchored expert reproduces your blind spots with extra confidence.

Later rounds do share the synthesis — reviewing a delta needs what changed and why.

## Tools

| | |
| --- | --- |
| Start a thread | `mcp__codex__codex` with `prompt`, `cwd`, `sandbox: "read-only"`, `approval-policy: "never"` |
| Continue | `mcp__codex__codex-reply` with `threadId` (not the deprecated `conversationId`) |
| Headless fallback | the `codex` CLI, when MCP is unavailable in a runner |

Verified 2026-08-14: the first call returns `{"threadId": "...", "content": "..."}` — the id arrives on the response, you do not request it. Reviewer ran GPT-5.4. `read-only` plus `approval-policy: never` stops the review stalling on an approval nobody watches.

## Where the log lives

**On the PR itself.** One comment per round: spatial context, attached to the thing it concerns, and it survives session loss where a scratch file does not.

The **thread id goes in the first comment**, explicitly. Without it, round 2 in a new session cannot continue the thread and repeats the independence work at full cost.

```markdown
**External review — round 1**
Thread: `019bdc91-1ea3-71c3-ab8f-bda225806061`
Artifact: `abc1234..def5678`

| Sev | Finding | Internal | Codex | Resolution |
|-----|---------|----------|-------|------------|
| H   | …       | found    | found | fixing     |
| M   | …       | missed   | found | accepted, see below |
```

## Closing the loop

**React to every finding with 👍 or 👎 as well as replying.** The reaction calibrates the reviewer; a reply is prose it does not learn from. 👍 for a correct finding even when you decline to act, 👎 for a wrong or inapplicable one — with the reason in the reply, so a human reads the disagreement too.

## Severity gates

| | Requirement |
| --- | --- |
| **H** | Blocks shipping. Resolve before close. |
| **M** | Fix, or record Chris's explicit acceptance. |
| **L** | Polish. Fix if cheap. |

**Converged** when no H stays open and every M is fixed or explicitly accepted. Accepting an M is Chris's call, not the agent's.

## Escalate, do not decide

Stop and present options when: a design tradeoff appears; Codex says "by design" (never dismiss it — escalate); scope would change; an architectural choice is implied; or a limitation is about to be accepted.

## Cost

Two Codex rounds is normal, three is a lot. Convergence gates terminate the loop — a third round with no new H or M stops.
