# Removal Risk

Use when the diff deletes code, tests, data, configuration, dependencies, or interfaces.

## Safe now

Require evidence for:

- static callers and references, including tests, docs, exports, manifests, configuration, generated files, and exact-name agent routes;
- dynamic, reflection, scheduled, migration-history, persisted-data, and external-consumer seams that text search cannot prove absent;
- a replacement path, or proof the capability is intentionally gone; and
- focused verification after deletion.

## Needs a separate decision

Defer removal while active consumers, migration, telemetry, user data, stakeholder authority, staged rollout, or recovery work remains. Report the precondition, owner, compatibility risk, validation signal, and rollback path. Never turn an unverified absence into "safe to remove."

Tests and docs retire with behavior only after proof they no longer describe a live contract. Historical migration and decision artifacts may stay authoritative after runtime code disappears.
