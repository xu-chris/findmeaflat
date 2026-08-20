# Violation Signatures

A signature makes a rule mechanically checkable. It lives beside the rule it enforces, never in a central list that drifts from it.

## The block

```markdown
## Violation Signature

Query: `rg -n 'transition-all' assets/`
Discriminator: only a finding when the element also declares an explicit property list, so the utility silently overrides it.
Known instance: assets/css/kanban-column.css:380
```

**Query** — one `rg` or `semgrep` invocation, tuned for recall. Over-matching is fine; the discriminator handles it.

**Discriminator** — one line separating a real hit from a safe-looking one. Without it the query produces noise and the lane trains you to ignore it.

**Known instance** — a `file:line` the query provably catches. **Not optional.** A query whose silence has never been contradicted measures itself.

## Where they go

**`docs/craft/` is primary.** Its 85 numbered rules (`ARC-`, `ASH-`, `CSS-`, `ELX-`, `GEN-`, `TST-`, `WEB-`) each take a signature under the rule they enforce.

**`docs/adr/` is secondary and optional.** ADRs have no id scheme, and most decisions resist mechanical detection. A forced signature there is worse than none.

## Writing the first ones

`docs/craft/dripfeed.md` carries a candidate register of roughly fifteen live violations, each citing `file:line`. That register is the validation corpus: every row is a known instance waiting for a query.

Write the query against the known instance, run it, confirm it catches that line, then run it across the tree and apply the discriminator to what comes back.

## When a candidate is rejected

A reverted or rejected fix is information about the signature, not about the codebase. Add the rejected shape to the discriminator as a named exclusion, so the next run does not raise it again.
