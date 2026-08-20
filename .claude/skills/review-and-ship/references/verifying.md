# Verifying Candidates

> Group candidates by `(file, line)` **before** dispatch — finders collide roughly 40% of the time, and grouping cuts verifier count by as much. One fresh `review-verifier` per group.

Each candidate returns exactly one of `CONFIRMED`, `PLAUSIBLE`, `REFUTED`. Keep the first two, drop the third.

## PLAUSIBLE is the default

**Never refute a candidate as "speculative" or "dependent on runtime state" when the state is realistic.** Realistic:

- concurrency races, including two Oban jobs on one record
- nil or missing values on a rare-but-reachable path — an error handler, a cold cache, an absent optional field
- falsy zero treated as missing
- off-by-one on a boundary the code does not explicitly exclude
- retry storms and partial failures
- a regex or allowlist that lost its anchor

Uncertainty means `PLAUSIBLE`. It never means `REFUTED`.

## REFUTED only when constructible from the artifact

- **Factually wrong** — quote the line that disproves it.
- **Provably impossible** — from a type, a constant, or an invariant visible in the packet.
- **Already handled in this change** — cite the guard.
- **Pure style with no observable effect.**

"No observable effect" gets abused: it means identical program behaviour, not a concern the reviewer finds uninteresting.

## Precision versus recall bias

`medium` runs precision-biased: drop a marginal candidate. `high` and above run recall-biased: keep it. Bias decides which way genuine uncertainty resolves; it never licenses refuting what the artifact supports.

**Standards and craft candidates still need their exact governing rule, whatever the bias.** Recall bias does not lower the evidence bar; it only breaks ties.
