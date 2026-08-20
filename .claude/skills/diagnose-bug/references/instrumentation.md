# Instrumentation

> Phase 4 of `diagnose-bug`. Each probe maps to one Phase 3 prediction and **changes one variable at a time.** Two at once teaches you nothing about either.

## Tool preference

1. **Evaluate against live state first.** `mcp__tidewave__project_eval` runs in the dev server with real data loaded — one evaluation beats ten log lines and needs no recompile. Unavailable headless; fall back to `mix run` or IEx.
2. **Targeted logs** at the boundaries separating the hypotheses.
3. **Never "log everything and grep".** That produces volume, not signal.

`mcp__tidewave__get_logs` reads the running server's log without shelling out. `mcp__tidewave__execute_sql_query` answers "what is in the row" without guessing from code.

## Tag every debug log

Give each debugging session a unique prefix and put it on every temporary log:

```elixir
require Logger
Logger.debug("[DEBUG-a4f2] submission=#{inspect(submission.id)} status=#{inspect(status)}")
```

Cleanup then becomes one `rg '\[DEBUG-a4f2\]'`. **Untagged debug logs survive into main; tagged ones die.** This project's `prestop` hook runs `mix compile --warnings-as-errors`, which misses a stray `Logger.debug`.

## Where to look in this system

| Symptom shape | Look first |
| --- | --- |
| Wrong data for one actor but not another | Ash policy with `actor` — evaluate the action both ways |
| Works in a test, fails in the app | The test used a different action, or bypassed the policy |
| Intermittent, worse under load | Oban retry or uniqueness, two jobs racing one record |
| Wrong after a redeploy | A migration that ran, or config differing only in prod |
| LiveView shows stale data | The event path never updated the assign, or PubSub topic mismatch |
| Fails only for scraped or LLM-derived records | Untrusted text reached something assuming shape |

## Performance regressions

**Logs are usually the wrong instrument.** Measure first, fix second:

1. Establish a baseline number — a timing harness, `:timer.tc/1`, or the query plan.
2. Bisect: halve the suspected path, measure again.
3. For database work, get the actual plan (`EXPLAIN ANALYZE` through `execute_sql_query`) rather than reasoning about the query.
4. Only then change anything, and re-measure against the same baseline.

A performance claim without a before and after number is a guess.

## Cleanup gate

Before the diagnosis is done:

- [ ] Every `[DEBUG-…]` line removed — grep the prefix to prove it
- [ ] Throwaway scripts and harnesses deleted, or moved to a marked scratch path
- [ ] The reproduction command still reproduces, so the next person starts where you stopped
- [ ] The hypothesis that proved correct is written down — what the next debugger needs

**Then ask what would have prevented this bug.** If the answer is architectural — no usable test seam, tangled callers, hidden coupling — say so on the issue as a `find-violations` or `plan-architecture` candidate. Recommend that *after* the diagnosis, when you know more than at the start.
