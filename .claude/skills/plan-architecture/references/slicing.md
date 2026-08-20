# Elixir, Ash, Phoenix, and Delivery Review

Answer only relevant questions; explain every material omission.

## Elixir and Monolith Boundaries

- Can transformations stay pure with effects at explicit shells?
- Does domain language yield deep, focused modules, not pass-through layers or query/utility junk drawers?
- Do `FindMeAFlat` (domains), `FindMeAFlat.Fetching` (portal adapters), and `FindMeAFlatWeb` (webhook, admin, MCP) exchange small explicit contracts through owning public interfaces?
- Does runtime state, concurrency, supervision, or fault isolation justify a process — not mere data organization?
- What fails independently, who supervises it, what state survives restart?
- Would an in-process call be simpler and safer than a new service boundary?

## Ash

- Which semantic actions and domain code interfaces express workflow?
- Do resources/actions own validation, authorization, changes, loads, and business results, not LiveViews/adapters?
- Can legitimate read variation use Ash query composition rather than combinatorial function names? Preserve semantic action filters, preparations, pagination bounds, policies, scope, tenancy, loads, and result shape.
- Does the trust boundary expose and parse external filter/sort inputs explicitly?
- Are actor/scope, identities, atomicity, transaction, and error/not-found shapes explicit?
- Do effects need idempotency, durable job handoff, or compensation?

## Phoenix and LiveView

- Does UI orchestrate public domain APIs without owning business rules?
- Who owns state, and what survives reconnect/navigation?
- Are loading, empty, validation, unauthorized, stale, and failed states visible and accessible?
- Can existing production components serve the flow? Which material reusable states need Storybook coverage?
- Can behavior be verified at the LiveView/component public boundary rather than private helper structure?

## Data and Fault Tolerance

- Does the data change require expand/migrate/contract, backfill, compatibility window, or invariant constraint?
- Timeout, retry, backoff, deduplication, cancellation, and poison-data semantics for external effects/Oban jobs?
- What prevents duplicate work after retry or node restart?
- Which metrics/logs prove success and diagnose partial failure without sensitive data?
- What is the safe-disable, rollback, or roll-forward path?

## Simplicity Checks

- Does current workflow demand every new resource, action, process, adapter, component, and abstraction?
- Is performance pressure measured before adding cache? Does the cache define its full key — scope/authorization dimensions included — and invalidation semantics?
- Can a tested Igniter task make a wide deterministic transformation safer and reusable?
