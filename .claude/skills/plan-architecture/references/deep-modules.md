# Deep Modules

**FindMeAFlat deltas only.** No `docs/craft/architecture.md` exists yet, so there are no `ARC-00n` ids to cite; [../../build/references/backend/architecture.md](../../build/references/backend/architecture.md) carries the rules meanwhile.

# Codebase Design

Design **deep modules**: much behaviour behind a small interface, at a clean seam, testable through it. Use this vocabulary and these principles when designing or restructuring code — for leverage (callers), locality (maintainers), testability.

## Glossary

Use these terms as written — no "component," "service," "API," or "boundary." Consistent language is what this buys.

**Module** — anything with an interface and an implementation. Scale-agnostic: function, class, package, or tier-spanning slice. _Avoid_: unit, component, service.

**Interface** — everything a caller must know to use the module correctly: type signature, invariants, ordering, error modes, required configuration, performance. _Avoid_: API, signature — type-level surface only.

**Implementation** — a module's body of code. Unlike **Adapter**: a small adapter can hold a large implementation (a Postgres repo), a large adapter a small one (an in-memory fake). Say "adapter" for the seam, "implementation" otherwise.

**Depth** — leverage at the interface: behaviour exercised per unit of interface learned. **Deep** = much behaviour, small interface. **Shallow** = interface nearly as complex as the implementation.

**Seam** _(Michael Feathers)_ — where you alter behaviour without editing in that place; the *location* of a module's interface. Placing it is its own decision, distinct from what sits behind it. _Avoid_: boundary — DDD's bounded context owns that word.

**Adapter** — a concrete thing satisfying an interface at a seam. Names a *role*, not substance.

**Leverage** — callers' payoff: more capability per unit of interface learned; one implementation pays back across N call sites and M tests.

**Locality** — maintainers' payoff: change, bugs, knowledge, verification concentrate in one place instead of spreading across callers. Fix once, fixed everywhere.

## Deep vs shallow

**Deep module** = small interface + lots of implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid):

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

Ask of any interface:

- Fewer methods?
- Simpler parameters?
- More complexity hidden inside?

## Principles

- **Depth belongs to the interface, not the implementation.** A deep module may compose small, mockable, swappable parts internally, outside the interface — **internal seams** (private, used by its own tests) alongside the **external seam** at the interface.
- **The deletion test.** Delete the module mentally. Complexity vanishes: a pass-through. Complexity reappears across N callers: it earned its keep.
- **The interface is the test surface.** Callers and tests cross the same seam; testing *past* it means the module is the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Introduce a seam only when something varies across it.

## Designing for testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them.**

   ```elixir
   # Testable through an explicit adapter.
   def deliver(message, mailer), do: mailer.deliver(message)

   # Hard to vary because implementation chooses dependency.
   def deliver(message), do: FindMeAFlat.Mailer.deliver(message)
   ```

2. **Return results, don't produce side effects.**

   ```elixir
   # Testable transformation.
   def calculate_total(cart), do: %{cart | total: discounted_total(cart)}

   # Harder to compose because calculation hides persistence.
   def apply_discount(cart), do: FindMeAFlat.Repo.update!(discount_changeset(cart))
   ```

3. **Small surface area.** Fewer methods = fewer tests needed. Fewer params = simpler test setup.

## Relationships

- A **Module** has exactly one **Interface** — its surface to callers and tests.
- **Depth** is a property of a **Module**, measured against its **Interface**.
- A **Seam** is where a **Module**'s **Interface** lives.
- An **Adapter** sits at a **Seam**, satisfying the **Interface**.
- **Depth** produces **Leverage** (callers) and **Locality** (maintainers).

## Rejected framings

- **Depth as ratio of implementation-lines to interface-lines** (Ousterhout): rewards padding. We use depth-as-leverage.
- **"Interface" as a language keyword or a module's public functions alone**: too narrow — interface covers every fact a caller must know.
- **"Boundary"**: overloaded with DDD's bounded context. Say **seam** or **interface**.

## Going deeper

- **Deepening a cluster given its dependencies** — [deepening](#deepening): dependency categories, seam discipline, replace-don't-layer testing.
- **Alternative interfaces** — [design it twice](#design-it-twice): dispatch the three architecture tastes from SKILL.md §2 under the shared read-only boundary, then compare on depth, locality, and seam placement.

---

## Deepening

# Deepening

Deepening a cluster of shallow modules safely, given its dependencies. Vocabulary: **module**, **interface**, **seam**, **adapter**.

## Dependency categories

Classify a candidate's dependencies. The category determines how tests cross the deepened seam.

### 1. In-process

Pure computation, in-memory state, no I/O. Merge only when one owner, a cohesive conceptual contour, and reduced caller knowledge survive the merge; otherwise keep the existing boundary. Test through the chosen public seam; no effect adapter.

### 2. Local-substitutable

Dependencies project-local test infrastructure can exercise. For FindMeAFlat database behavior use the real PostgreSQL data layer through Ecto SQL Sandbox — never PGLite or an invented database adapter. For portal HTML, use a stored fixture per portal; never hit a live portal from a test. Use an in-memory filesystem only where the owning boundary provides one. The seam stays internal; never expose a port solely for tests.

### 3. Remote but owned (Ports & Adapters)

Your own services across a network boundary (microservices, internal APIs). Define a **port** (interface) at the seam. The deep module owns the logic; inject the transport as an **adapter** — in-memory for tests, HTTP/gRPC/queue in production.

Recommendation shape: *"Define a port at the seam, with an HTTP adapter for production and an in-memory adapter for tests, so the logic sits in one deep module though deployed across a network."*

### 4. True external (Mock)

Third-party services (Stripe, Twilio, etc.) you don't control. The deepened module takes the external dependency as an injected port; tests provide a mock adapter.

## Seam discipline

- **One adapter means a hypothetical seam. Two adapters means a real one.** Introduce a port only when at least two adapters are justified (typically production + test). A single-adapter seam is indirection.
- **Internal vs external seams.** Internal seams stay private to the implementation and its own tests. Never expose one through the interface because tests use it.

## Testing strategy: replace, don't layer

- Old shallow-module unit tests may become redundant once interface tests prove the same behavior and failure boundaries. Delete only that demonstrated overlap; keep distinct regression evidence.
- Write new tests at the deepened module's interface. The **interface is the test surface**.
- Assert observable outcomes through the interface, not internal state.
- Tests should survive internal refactors — they describe behaviour, not implementation. A test that changes with the implementation tests past the interface.

---

## Design it twice

# Design It Twice

Explore alternative interfaces for a chosen deepening candidate with this parallel sub-agent pattern. From "Design It Twice" (Ousterhout) — your first idea is rarely the best.

Vocabulary: **module**, **interface**, **seam**, **adapter**, **leverage**.

## Process

### 1. Frame the problem space

Explain the problem space to the user before spawning sub-agents for the chosen candidate:

- Constraints any new interface must satisfy
- Dependencies it would rely on, and their category (see [deepening](#deepening))
- A rough code sketch making the constraints concrete — not a proposal

Show it, then proceed to Step 2. The user reads while the sub-agents work in parallel.

### 2. Dispatch design variants

Dispatch the three architecture tastes from SKILL.md §2 in parallel. Give every child the same neutral packet of verified facts: fixed artifact paths, coupling details, dependency category from [deepening](#deepening), what sits behind the seam, constraints, output contract. Add one declared variation constraint per child:

- Agent 1: "Minimize the interface — aim for 1–3 entry points max. Maximise leverage per entry point."
- Agent 2: "Maximise flexibility — support many use cases and extension."
- Agent 3: "Optimise for the most common caller — make the default case trivial."
- A fourth agent needs a stated reason in the output: "Design around ports & adapters for cross-seam dependencies."

Each child is one `taste-*` agent, handles one variation, stays read-only, cannot delegate. Put vocabulary from `plan-architecture` §1 and `CONTEXT.md` in the shared packet so children name things consistently with architecture and domain language. Never leak a sibling's proposal or the main agent's preference into a packet.

Each sub-agent outputs:

1. Interface (types, methods, params — plus invariants, ordering, error modes)
2. Usage example showing how callers use it
3. What the implementation hides behind the seam
4. Dependency strategy and adapters (see [deepening](#deepening))
5. Trade-offs — where leverage is high, where it's thin

### 3. Verify, present, and compare

The main agent verifies every returned claim against the fixed artifacts, preserves material dissent, presents designs sequentially, then compares them in prose by **depth** (leverage at the interface), **locality** (where change concentrates), and **seam placement**. Children never edit the canonical design.

Then recommend: the strongest design and why. Propose a hybrid when elements from different designs combine well. Be opinionated — the user wants a strong read, not a menu.
