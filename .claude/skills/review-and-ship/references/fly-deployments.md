# Fly Deployment Review

Read this for database migrations, deployment-sensitive runtime or release code, image entrypoints, `fly.toml`, and flyctl deployment workflows. Name every enabled path that can ship the artifact, or one maintainer-selected path. Identify each path's flyctl binary and verify its execution order against matching source and current Fly documentation. Floating installers (`latest`, `master`), unknown provenance, unidentified paths, missing evidence, or conflicting evidence make safety `unknown` and block shipping.

## Distinct mechanisms

| Mechanism | What it proves | What it does not prove |
| --- | --- | --- |
| `release_command` Machine | The command exited 0 in a temporary Machine from the candidate image | A disposable database, reversible side effects, or old code supporting the resulting schema |
| Machine check | An optional command reaches and tests one updated Machine through `FLY_TEST_MACHINE_IP` | That the migration was rehearsed or runs again |
| Smoke and health checks | An updated Machine starts, listens, and passes configured service checks | That old code fits schema `release_command` already changed |
| Rolling, canary, or blue-green strategy | Fly replaces Machines and shifts traffic under the chosen strategy | That Fly delays committed migration effects until every old Machine stops |
| Temporary Machine lifecycle | Fly destroys one-purpose compute after the command exits | That Fly reverses any external side effect |

**Temporary describes Machine lifecycle, not external side effects. Inventory every database, API, queue, object-storage, email, or other write; prove each one's transaction, exclusion, retry, and recovery boundaries.** A `release_command` targeting production does the real operation once per attempt, and a retry, redeploy, or manual invocation runs it again. Destroying its Machine undoes no committed effect. A non-zero, timed-out, killed, or unknown exit stops rollout and proves nothing about external state.

## Current sequence

flyctl v0.4.82 runs this order for a Machines deployment. Treat it as historical evidence when the runner uses another version.

| Order | flyctl action | Review implication |
| ---: | --- | --- |
| 1 | Build or resolve the candidate image | Old Machines still serve the current schema |
| 2 | Create a temporary `release_command` Machine from the candidate image and app configuration | Temporary compute may hold production credentials and network access |
| 3 | Run the command and wait for exit | Successful external writes are real; the command must tolerate another attempt |
| 4 | Stop before Machine updates on a failed or unknown outcome | Inspect transaction state, external effects, and the migration ledger before calling the database unchanged or the retry safe |
| 5 | Start the rolling, canary, blue-green, or immediate update after success | Old code may stay live against the post-command schema |
| 6 | Run Machine checks once an updated Machine starts, then smoke and service health checks | They test candidate behavior; they do not replay the migration or prove old-code compatibility |

**Never model the production-targeting command as a rehearsal, preflight, validation run, or "test migration, then real migration" unless the repository proves the first execution is isolated and a separate second execution exists.**

## Compatibility gate

Model every success, failure, retry, concurrency, rollback, worker, and straggler state users or background processes reach. Name exact releases and schemas, not "old" and "new". A healthy final state does not repair an invalid transition.

| State | Application code that may serve | Database state to prove |
| --- | --- | --- |
| Before `release_command` | Current Machines and workers | Pre-command schema and data |
| Command running | Current Machines and workers | In-transaction, locked, partially changed, or externally visible |
| Command exited non-zero | Current Machines and workers | Rolled back, partially changed, or externally changed; inspect, do not infer |
| Command timed out, was killed, or ended unknown | Current Machines and workers | Unknown until the ledger and every external effect are checked |
| Retried or concurrent attempt | Current Machines, workers, and more than one release-command Machine | Idempotency, exclusion, duplicate-write, and race behavior |
| Command succeeded, before first update | Current Machines and workers | Post-command schema and data |
| Rolling, canary, or blue-green transition | Current, candidate, straggler, and rollback-target releases | Post-command schema and data |
| Rollout failed | Surviving candidate plus unchanged releases | Post-command schema unless recovery changed it |
| Old image restored | Restored release, surviving workers, possible candidate stragglers | Post-command or recovered schema, proven separately |
| Rollout completed | Candidate Machines and workers | Post-command schema and data |

**Blue-green keeps old Machines serving until traffic switches; prove old-code/new-schema compatibility. The immediate strategy shortens the overlap, but flyctl still runs `release_command` before stopping old Machines.**

**Compatibility decisions**

| Evidence result | Required action |
| --- | --- |
| Every reachable code-schema-data state is `valid` | Proceed; attach the matrix and evidence identities to the frozen packet |
| Any reachable state is `invalid` | Report a correctness finding and block shipping until the artifact implements a proven safe sequence |
| Any required state or external effect is `unknown` | Block shipping and name the evidence, access, or authority needed; never report a clean deployment |

**Additive DDL or a runbook alone proves nothing. Prove runtime behavior, data invariants, lock effects, and enforcement of any traffic-stop boundary. A maintenance boundary holds only when proxy traffic, autostart, workers, scheduled jobs, and manual Machines cannot run incompatible code from command start until candidate health passes. Expand/contract and custom orchestration are also safe sequences.**

**Write the matrix outside hidden reasoning: the matching card under `docs/proposals/` when one exists, otherwise the PR body or final handoff. Each row names the state, exact serving releases and workers, schema/data state, evidence identity, accepted invariant, and verdict. The governing spec or maintainer defines acceptable loss and downtime; an agent cannot turn unaccepted risk into `valid`.**

## Evidence

Capture each snapshot before angle fan-out and add it to the frozen packet. Record versions, binary commit or checksum when available, timestamps, release IDs, query or log boundaries, and consulted documentation passages with access date. Refresh mutable production evidence once before git handoff. Unchanged values need only a new timestamp; a changed value or identity needs a re-freeze, a repeated Fly review, and another final refresh.

| Evidence | Status | What to verify | Missing result |
| --- | --- | --- | --- |
| Repository `fly.toml` and deploy workflow | Required | Release command, strategy, checks, wrappers, concurrency controls, and the exact flyctl binary per enabled or selected path | `unknown`; a workstation or prior-run version cannot substitute |
| Active releases and migration ledger | Required for a production-targeting command, migration, compatibility claim, or rollback claim | Every application or worker release that can run, exact database state, and rollback targets | Request authorized evidence; credentials alone do not grant production access |
| Migration and command implementation | Required | Transactions, nontransactional DDL, locks, data invariants, external writes, idempotency, timeout, retry, and recovery behavior | `unknown` for every unsupported state |
| Successful and failed deploy logs | Corroborative when available | Latest success and failure for the same app and workflow since the last relevant deployment-config change | Absence alone does not make state `unknown`; contradiction does until resolved |
| Matching flyctl source and current Fly documentation | Required | Source for the runner version defines execution order; documentation defines the supported contract | Resolve disagreement before shipping; unresolved conflict stays `unknown` |

**Inventory external effects as `source | effect | transaction or exclusion | retry behavior | recovery proof | evidence`, including indirect ones from database triggers, callbacks, stored procedures, queue consumers, dependencies, and environment-driven behavior. A paper runbook proves no recovery. Destructive or non-invertible effects require an exercised rollback or a verified backup restore. Lock, backfill, and timing claims require the same schema plus representative row counts, value distributions, concurrency, timeouts, and resource limits.**

**Match proof to claim: source and config establish execution order; compatibility tests establish code-schema behavior; production-shaped data and concurrent workload establish backfill, lock, and timing claims; exercised recovery establishes reversibility. Unresolved source, documentation, log, or runtime disagreement stays `unknown`.**

**A zero exit proves only that the command returned success, never schema compatibility. Committed changes survive a later rollout failure unless tested transaction or recovery evidence proves reversal.**

## Sources

| Source | Question answered |
| --- | --- |
| [Fly configuration: one-off commands before deployment](https://fly.io/docs/reference/configuration/#run-one-off-commands-before-releasing-a-deployment) | What environment and lifecycle does `release_command` get? |
| [Fly seamless deployments: release commands and schema compatibility](https://fly.io/docs/blueprints/seamless-deployments/#one-off-tasks-with-release-command) | What compatibility responsibility stays with the application author? |
| [flyctl v0.4.82 deployment order](https://github.com/superfly/flyctl/blob/9656e781dd988f28bfdd358abd403084f8ef9354/internal/command/deploy/machines_deploymachinesapp.go#L463-L485) | Where does the release command run relative to the update strategy? |
| [flyctl v0.4.82 release-command Machine](https://github.com/superfly/flyctl/blob/9656e781dd988f28bfdd358abd403084f8ef9354/internal/command/deploy/machines_releasecommand.go) | How is the temporary command Machine created, started, awaited, and destroyed? |
| [flyctl v0.4.82 Machine checks](https://github.com/superfly/flyctl/blob/9656e781dd988f28bfdd358abd403084f8ef9354/internal/command/deploy/machinebasedtest.go) | How do optional Machine checks differ from the release command? |
