# Interface Behaviour

Behaviour, states, and copy. Visual craft — surfaces, layout, type, colour, accessibility — lives in `build/references/frontend/interface.md`.

**FindMeAFlat deltas only.** No `docs/craft/phoenix-liveview.md` exists yet, so there are no `WEB-00n` ids to cite. **Most UX here is Telegram conversation design, not screens** — inline keyboards, command flows, and message copy in German.

Own the behavior-level decision. The references below supply appearance evidence; `build` owns implementation.

## Entry and authority

Choose one mode:

- `design`: define behavior and state contracts for a stable problem;
- `audit`: inspect an existing interface and report actionable usability failures;
- `copy`: revise user-facing language inside a defined interaction.

Design and audit authorize no repository mutation. Behavior that changes domain rules, authorization, or persistence gets resolved in the shape before any UI spec.

Read the current flow, shared components, nearby tests and stories, applicable ADRs, and the guides `docs/craft/README.md` routes to. Existing UI is evidence, not automatic target architecture.

## Concern routing

Read only the reference the surface needs; this step synthesizes their evidence and owns the result. Every target below is a repository file, not a skill.

| Condition | Read |
| --- | --- |
| Semantics, keyboard, focus, forms, assistive technology, zoom, reduced motion | [accessibility.md](../../build/references/frontend/accessibility.md) |
| Grouping, alignment, reading order, responsiveness, direction, surfaces, icons, static visual detail | [interface.md](../../build/references/frontend/interface.md) |
| Type hierarchy, legibility, wrapping, mixed-direction text | [typography.md](../../build/references/frontend/typography.md) |
| Semantic color, contrast, theme, palette, gamut | [color.md](../../build/references/frontend/color.md) |
| Labels, instructions, errors, empty states, tone | the `## Copy` section of [interface.md](../../build/references/frontend/interface.md) |

Motion is a separate capability. Name an effect with [motion-vocabulary.md](../../build/references/frontend/motion-vocabulary.md); decide in the shape whether motion belongs; construct it only inside approved implementation, through [motion.md](../../build/references/frontend/motion.md).

## Behavioral defaults

Every state answers three questions: where am I, what happened, what can I do next?

- Speak a flat-hunter's language — Wohnung, Inserat, Miete, Kaltmiete, Wohnfläche, Zimmer, Bezirk, Mietspiegel, Hausverwaltung. Never expose resource, action, policy, job, Oban, or transport terminology.
- Leave the user in control: provide exits, preserve entered work where safe, prefer undo over confirmation when reversal is honest.
- Prevent invalid actions through constraints and clear choices; allow incomplete intermediate work where the domain permits.
- Keep recognition close to the decision. Never make users memorize identifiers, prior screens, hidden rules, or unexplained icons.
- Show system state without timing guesses. Feedback cannot rest on motion, color alone, or a transient toast for important recovery.
- Keep the common task direct. Reveal advanced choices when relevant instead of making every user parse them.
- Use one term per concept across navigation, headings, actions, and messages.
- Never silently change domain data, send external effects, or infer consequential consent from navigation.

## State contract

Specify only states the flow reaches; omit no applicable state:

| State | Required answer |
| --- | --- |
| Initial | What this surface is for and the first action available |
| Empty | Why nothing is here, whether that is normal, the next useful action |
| Editing | Current values, constraints, unsaved status, safe exit |
| Validating | Which field owns each error; no loss of input or focus |
| Submitting/loading | What is happening, whether repeating is safe, how progress or cancellation works |
| Success | What changed and the next meaningful destination or action |
| Failure | What failed, what remains safe, a realistic recovery action |
| Unavailable | Why the option cannot be used and what would make it available, when known |
| Destructive | Exact object and consequence, scope of deletion, reversibility, specific confirm/cancel labels |
| Reconnected/stale | Which state is authoritative after LiveView disconnect, retry, or concurrent change |

Authentication and sensitive-data flows also define session expiry, cross-tab behavior, recovery without account enumeration, clipboard/reveal behavior, and which data must never reach URLs or logs.

## Design procedure

1. Name the user, goal, entry point, completion condition, and realistic interruption.
2. Trace the whole existing flow before changing one screen: back navigation, refresh, reconnect, retry, duplicate submission where relevant.
3. Separate domain facts from presentation choices. Never solve a domain ambiguity with copy or disabled controls.
4. Write the state contract and action consequences, defining keyboard and accessibility behavior at the same time, not after layout.
5. Compare alternatives by task cost, error prevention, recovery, and fit with current FindMeAFlat patterns.
6. Return a compact behavior specification: states, transitions, labels, failure recovery, focus/navigation behavior, unresolved decisions.

## Audit procedure

Exercise the interface as a new user, a returning user with data, and a user who fails or interrupts the task. Inspect narrow and wide layouts plus keyboard flow where applicable. Take exact evidence from the concern references; do not repeat their rules.

Report only confirmed, user-visible findings. Each names severity, location, observed behavior, realistic failure scenario, desired behavior, and governing project source. `HIGH` for blocked tasks, hidden consequences, inaccessible essential behavior, or unrecoverable loss; `MEDIUM` for meaningful confusion or avoidable task cost; `LOW` for bounded consistency or polish.

End with `Block`, `Needs changes`, or `Approve`, plus checks run and residual uncertainty. Route an approved fix through `build`; never edit during audit.

## Copy mode

Revise the copy against the `## Copy` section of [interface.md](../../build/references/frontend/interface.md), then return complete replacements in their interaction context. Check interpolation, pluralization, error recovery, narrow-width wrapping, and terminology against nearby product copy.

FindMeAFlat copy states the event, then the next action, and stops. Two short sentences for an error; present tense for a success. Avoid fake hesitation, rhetorical questions, exclamation marks, affected colloquialisms, corporate cuteness, em dashes, and hyphens used as dashes.

**User-facing copy is German.** Telegram supplies `language_code`; German is the default, English the fallback. Say “Wohnung”, “Inserat”, “Suche” — the words the portals themselves use. Never claim a listing *is* a scam or *violates* the Mietpreisbremse: state the observation and the reference value, and let the reader judge.
