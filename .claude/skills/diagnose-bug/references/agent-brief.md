# Agent Brief

An issue brief is a durable behavioral contract for work labeled `afk` (an agent may do it) or unlabeled (human). Issue discussion stays provenance, not specification.

Describe stable interfaces and behavior, not file paths, line numbers, or a prescribed implementation. Include independently verifiable acceptance criteria and explicit non-goals. On a pull request, current behavior means the existing diff and desired behavior means only the remaining work.

```markdown
## Agent Brief

**Category:** bug / enhancement
**Summary:** one-line outcome

**Current behavior:**
What happens now, including verified failure or current diff gaps.

**Desired behavior:**
Observable result, edge cases, and error behavior.

**Key interfaces:**
- Stable type, command, domain concept, or contract and required change

**Acceptance criteria:**
- [ ] Independently testable result

**Out of scope:**
- Adjacent behavior excluded from this item
```
