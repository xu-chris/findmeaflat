# FindMeAFlat ADR Format

ADRs live flat in root `docs/adr/` under three-digit sequential numbering: `001-decision-slug.md`, `002-decision-slug.md`. No context-specific ADR directories.

Create an ADR only after current source implements the decision and you have checked the evidence. An unimplemented decision, however clear, goes in the Bet Go card's `CONCEPT.md` → `Decision Made`, never in `docs/adr/`.

## Template

```markdown
# {Short title of the decision}

**Applies to:** `lib/find_me_a_flat/listings/`, `lib/find_me_a_flat/fetching/`
**Status:** Superseded by ADR-041

## Problem Statement

{What failure, constraint, or architectural pressure required a decision.}

## Decision Made

{What current source implements, and why. Link the implementation evidence.}

## Consequences & Tradeoffs

{Benefits, costs, risks, rejected alternatives, known limits.}

### Violation Signature

Query: `rg -n 'pattern' lib/`
Discriminator: {what separates a real hit from a safe-looking one}
Known instance: {file:line that proves the query catches something}
```

The three H2 headings are **mandatory and ordered** — 33 existing records use them, `docs/AGENTS.md` requires them. Optional detail goes in H3 subsections beneath. The two lines above the first H2 add to them, replacing nothing.

### `Applies to` — required

One line naming the paths or surfaces this decision governs.

**This is the highest-value line for an agent reader.** Without it, judging relevance means opening all 35; with it, a grep decides. One line to write, a load saved every time someone touches the area.

Name real paths. Directories usually beat files — files move.

### `Status` — only when not active

**Omit it for a live decision.** Absence means active, which keeps every existing record valid.

Write it only for `Superseded by ADR-NNN` or `Deprecated: {why}` — the one case the three headings cannot express, and the one that actively misleads: an agent obeying a replaced decision faithfully reproduces architecture the project has left.

**Never `Proposed`.** An unimplemented decision lives in the Bet Go card's `CONCEPT.md`; location records that state.

Superseding an ADR means editing the old one to point forward *and* naming in the new one what it replaces. A one-directional link is findable only from the side that already knows.

### `Violation Signature` — optional

Most decisions are not mechanically detectable, and a forced signature is worse than none. Add one when a `rg` or `semgrep` query separates conforming from violating code.

**The known instance is not optional when a signature is present.** `find-violations` distrusts a query's silence until it has caught something — an unvalidated query returning nothing measures your regex, not the codebase.

## Numbering

Scan root `docs/adr/` for the highest three-digit number and increment. ADR numbering runs independent of proposals, drafts, and research. Never renumber existing records to close gaps.

## When to offer an ADR

All three must hold, and current source must implement the decision:

1. **Hard to reverse** — changing your mind later costs something meaningful
2. **Surprising without context** — a future reader will wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — genuine alternatives existed and you picked one for specific reasons

Skip an easy-to-reverse decision — you'll reverse it anyway. An unsurprising one leaves nobody wondering. Without a real alternative, nothing remains beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target — not every library, only the ones taking a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The no-s match the yes-s in value.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything a reasonable reader would assume the opposite of. These stop the next engineer from "fixing" something deliberate.
- **Constraints enforced by current source.** Record how code or configuration reflects the constraint. An external constraint with no implemented consequence belongs in research or business documentation, not an ADR.
- **Rejected alternatives when the rejection is non-obvious.** Record picking REST over GraphQL for subtle reasons — otherwise someone suggests GraphQL again in six months.
