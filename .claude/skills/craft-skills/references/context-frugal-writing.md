# Context Budget

> Where a sentence belongs, and what it costs there. Run a density pass **after** a skill is structurally stable — compressing what you are still shaping destroys the shaping.

## The three tiers

| Tier | Cost | Earns a place only if |
| --- | --- | --- |
| **Always on** — `AGENTS.md`, every `description` | paid every turn, forever | it changes which skill gets called, or prevents a wasted turn on *any* task |
| **On trigger** — `SKILL.md` body | paid when the skill runs | it is a decision point, a gate, or the routing table |
| **On demand** — `references/`, `examples/` | ~zero until read | it is method, taxonomy, or depth needed sometimes |
| **Never loaded** — `scripts/` | zero; executed | it is mechanical and checkable |

Depth is cheap on demand and expensive always-on. **Most compression work moves sentences down a tier rather than deleting them.**

Budgets this repository enforces: `AGENTS.md` around 100 lines, `SKILL.md` at most 150, a project reference at most ~300, and every skill `name` + `description` together under **8,000 characters** — what Codex allots for the skill listing. `.agents/bin/check-harness.sh` measures the last one.

## Decision locality

**Keep facts that determine a branch, gate, or outcome beside that decision.** "Beside" means the same paragraph, table row, numbered step, or helper invocation with named arguments. Applicability facts — threshold, precondition, exception, pressure, accepted criterion — stay local. References own execution method, taxonomy, examples, and cited authority. A cold reader must decide whether the rule applies without chasing a link.

**Promote after reuse:** Keep a one-use method beside its consumer. Promote only after a second independently required consumer calls the same inputs and expects the same result. Never add a consumer to justify extraction; extraction alone earns no distance.

## What to cut outright

Classify every line:

| Class | Test | Do |
| --- | --- | --- |
| **Obvious** | derivable from `ls`, `--help`, or framework convention | cut |
| **Gotcha** | repo-specific failure that wastes a turn when unknown | keep |
| **Taste** | counter to the industry default | keep, **with the reason** |
| **Pointer** | depth someone occasionally needs | keep, with a real path |

Anything a dependency's `usage-rules.md` or hexdocs covers counts as Obvious here, however useful elsewhere. Cite the authority instead: shorter, and current.

## Compression that does not lose rules

1. **Cut hedges.** "It is generally recommended that you should consider" → "Prefer".
2. **Table over prose** whenever the content is a mapping. Ten rows scan faster than ten paragraphs and survive skimming.
3. **State the trigger, not the contents.** "Touching Oban jobs → read `x.md`" beats a paragraph describing `x.md`'s contents.
4. **One excellent example.** Porting is cheap; maintaining five is not.
5. **Delete restatement.** If a craft rule says it, cite the id and stop.
6. **Real repo paths, never invented ones.** A broken real path fails loudly; a fabricated one fails silently.
7. **Defaults with reasons travel; bare absolutes do not.** "Prefer X over Y, because Z" survives the unforeseen case. Reserve absolutes for irreversibility, security, and data loss.

## The test

**Enforceability:** Read the compressed version cold. Can the reader name the required action, trigger, exception, and failure response?

**Decision locality:** Move each determining fact from a reference, helper default, or earlier callback beside the decision. Otherwise expose it through the helper contract at the call site.

**Semantic conservation:** Compression that drops a condition, threshold, or exception changes the rule. Restore it and cut elsewhere.

**Skimmer visibility:** Give the compressed version to `reader-skimmer`. Move or bold anything it drops.
