# Feedback Loops

> Phase 1 of `diagnose-bug`, worth disproportionate effort. A pass/fail signal that goes red on *this* bug makes bisection, hypothesis-testing and instrumentation mechanical. Without one, reading code will not save you.

**Be aggressive. Be creative. Refuse to give up.** The right loop fixes 90% of the bug.

## Ways to construct one, in roughly this order

1. **Failing test** at whatever seam reaches the bug — unit, integration, or `Phoenix.LiveViewTest`.
2. **HTTP script** against the running dev server. Read this worktree's port from `.claude/worktree.md`; never assume 4000.
3. **`mix run` or an IEx script** with a fixture input, diffed against a known-good snapshot.
4. **Tidewave `project_eval`** — runs against the *live* dev server with real state loaded. Often fastest here; unavailable headless.
5. **Browser script** through the preview tools — drives the LiveView, asserts DOM, console, network.
6. **Replay a captured artifact.** Save the real payload, Oban job args, LLM response, or scraped page to disk, then replay it through the code path in isolation.
7. **Throwaway harness.** A minimal subset — one context, mocked collaborators — reaching the bug in one call.
8. **Property or fuzz loop.** For "sometimes wrong output", many random inputs, watching for the failure mode. `StreamData` if already available.
9. **Bisection harness.** Appeared between two known states? Automate "set state X, check, repeat" so `git bisect run` drives it.
10. **Differential loop.** Same input through two versions or two configs, diff the outputs.

## Tighten it

Treat the loop as a product; improve the first one you get:

- **Faster** — cache setup, skip unrelated init, narrow the test scope.
- **Sharper** — assert the specific symptom, not "did not crash".
- **More deterministic** — pin time, seed randomness, isolate the database, freeze network.

A 30-second flaky loop barely beats no loop. A 2-second deterministic one is a debugging superpower.

## Non-deterministic bugs

Aim for a **higher reproduction rate**, not a clean reproduction. Loop the trigger 100×, parallelise, add stress, narrow timing windows, inject sleeps. A 50%-flake bug is debuggable; a 1% one is not — keep raising the rate.

Concurrency-shaped bugs dominate this system: Oban jobs racing, LiveView events arriving out of order, check-then-act on a record two actors reach.

## Completion criterion

Phase 1 ends when you can name **one command you have already run at least once** — show the invocation and its redacted output — and it is:

- [ ] **Red-capable** — drives the bug path and asserts the user's exact symptom: red now, green after the fix. Not "runs without erroring".
- [ ] **Deterministic** — same verdict every run, or a pinned high reproduction rate.
- [ ] **Fast** — seconds, not minutes.
- [ ] **Agent-runnable** — runs unattended.

**No red-capable command, no Phase 2.**

## When you cannot build one

Stop and say so. List what you tried from the options above. Ask for the environment that reproduces it, a redacted captured artifact, or permission to add temporary instrumentation.

**Do not hypothesise without a loop.** Headless, post that as the diagnosis outcome and apply no label.
