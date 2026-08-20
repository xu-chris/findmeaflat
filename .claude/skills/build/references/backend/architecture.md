# Project Architecture and Code Conventions

**FindMeAFlat deltas only.** There is no `docs/craft/architecture.md` and no `docs/adr/` in this repository yet, so there are no `ARC-00n` ids to cite — **this file is the rules until one exists.** When an ADR set is created, move these rules there and reduce this file to deltas.

Project reference only; inherit authority and scope from the calling skill.

## Boundaries

- Give each view one owning context and route writes through it. Other contexts may supply explicit read data when the page composes them; inspect coupling, do not impose a numeric limit.
- Context functions accept IDs, never foreign-context structs. Views pass IDs + changesets.
- Never pass `conn` or `socket` to contexts.
- Context aliases: first-level only (`FindMeAFlat.*`). External entity matches: full path, e.g. `%{__struct__: FindMeAFlat.Listings.Listing}`.
- Single-caller view composition stays in LiveView. Add a context function only for own invariants or multiple callers. Never invent a cross-cutting orchestrator.
- Decouple contexts with typed event structs: DTOs, not pub/sub.
- There are no legacy god modules to avoid yet. The Node predecessor's equivalent is `lib/flatfinder.js`, which mixes fetching, normalising, filtering, deduping and notifying in one class — do not reproduce that shape in Elixir.

## Current decisions

Recorded in `docs/proposals/3-bet-go/001-elixir-multi-tenant-rewrite/`. That card has a **recorded Bet Go** and a `PLAN.md`; no Elixir code exists yet. Where PLAN and this file disagree, PLAN is newer — say so rather than silently following either.

- **Ash, not plain Ecto contexts.** This app is mostly policy plus background jobs, which Ash policies and AshOban triggers express declaratively.
- **AshAuthentication is decided, for the admin surface and the MCP server only.** Users authenticate through Telegram identity (`chat.id`) and never touch the web app. Pin the stable 4.x line, not the v5 RCs.
- **Model portal adapters as behaviours, never Ash resources.** `Portal` and `SelectorSet` are resources because they are data; the fetch and parse logic behind them is a behaviour with two implementations.
- **Extraction rules live in data (`SelectorSet` rows), not code.** Portals change markup several times a year; repairing one must not require a deploy.
- **Oban OSS, not Pro.** Per-portal pacing is a `PortalGate` GenServer holding a token bucket, because OSS has per-queue concurrency but no per-key rate limiting.
- **Store every parsed listing permanently**, including full `description` and `image_urls`. The accumulated dataset is the product; those two fields are unrecoverable once a listing is delisted.

## Writing code

Build data-transformation pipelines. Prefer clauses and guards over conditionals. Reuse before adding. Fix adjacent smells only inside accepted touched scope.

Read [igniter.md](igniter.md) for generated or large deterministic changes; it owns maintained-generator selection, semantic rewrites, and the dry-run/apply/no-op gates.

Trace data across boundaries before moving an abstraction. If a boundary already transforms it, delete the wrapper. Verify with `project_eval` when the dev runtime runs.

### Conventions

- Same-module reuse: keep the helper private. Cross-module reuse: add one documented public `def` to the owning module; call it directly.
- Keep tightly coupled modules in one directory. Put a single-owner extension module in the owner's file, owner first. Split only when independent ownership or consumers emerge.
- **CRC:** Give each module one core type. Constructors create it. Reducers transform it to same type and stay pipeable. Converters return another type.
- Group same name/arity functions together. Pipe-first arguments.
- Use `Stream` for large/infinite collections; `Enum` for finite data.
- Use behaviours for compile-time contracts; protocols for runtime data polymorphism.
- Add defensive code only at external boundaries.

### Naming

- Name domains `FindMeAFlat.Listings`; resources `FindMeAFlat.Listings.Listing`; LiveViews `FindMeAFlatWeb.PortalHealthLive.Index`; queries `FindMeAFlat.Listings.Listing.Query`.
- Domain language is `Subscriber`, `Search`, `SearchPortal`, `Filter`, `Listing`, `Delivery`, `Portal`, `SelectorSet`, `Provider`. Never "user", "job", or "scraper".
- Use readable domain terms, not technical names.
