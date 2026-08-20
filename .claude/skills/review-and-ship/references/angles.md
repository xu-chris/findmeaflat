# Angles

> One angle per `review-finder`, read-only and blind to the others. Stay inside your angle; another finder owns what you notice outside it.

**Every candidate names one axis:** `spec-correctness`, `standards`, or `craft`. Standards and craft candidates cite their exact governing rule *and* a concrete coupling, knowledge leak, duplicated rule, or regression. **A preference without that cost is not a finding.**

## Correctness — A through E

**A — line-by-line diff scan.** Every hunk plus its enclosing function; bugs in unchanged lines of a touched function count. Hunt inverted conditions, off-by-one, nil access, missing `await`/`Task.await`, falsy-zero handling, wrong-variable copy-paste, swallowed errors, unescaped regex metacharacters.

**B — removed-behaviour auditor.** For every deleted line, name the invariant it enforced, then find where the new code re-establishes it. No replacement is a candidate.

**C — cross-file tracer.** Callers and callees of every changed public seam: new preconditions, changed return shapes, new exceptions, ordering dependencies, exports, tests, docs, dynamic consumers.

**D — language pitfalls.** Elixir process and pattern semantics, atom exhaustion, unsafe deserialization, `String.to_atom/1` on external input, SQL injection through raw fragments, DST drift, float equality.

**E — wrapper and proxy correctness.** Where a cache, proxy, decorator, adapter, or form wraps another object, verify every method reaches the wrapped instance rather than a registry, session, or global.

## Cleanup

**Reuse** — new code re-implementing an existing helper; name the helper instead. **Simplification** — redundant or derivable state, copy variation, deep nesting, dead branches, unnecessary interfaces. **Efficiency** — repeated I/O or computation, sequential independent work, blocking hot paths, unbounded traversal, closures retaining scope. **Altitude** — a special case layered on shared infrastructure means the fix is not deep enough; needs a concrete changed cost, not a preference. **Conventions** — survives only by quoting both the exact rule and the exact offending changed line.

## Audit — `xhigh` and above

**ux-behavior** — states, recovery, empty and error paths, confirmation, user-facing copy. Against `.claude/skills/shape/references/ux-behavior.md`.

**visual-design** — surfaces, spacing, optical alignment, and the presence *or absence* of motion. Against `.claude/skills/build/references/frontend/interface.md` and its `motion.md`.

## Sweep — `xhigh` and above

One fresh `review-sweep` gets the verified list and the packet, and hunts **only gaps**: moved code that dropped a guard or an anchor, second-tier language footguns, shrunk lock scope, predicate methods with side effects, setup and teardown asymmetry in tests, flipped configuration defaults.

At most eight new candidates, verified through the same ladder. **An empty sweep is a correct result — never pad it.**
