# Motion

Naming a vague effect: [motion-vocabulary.md](motion-vocabulary.md). Where motion belongs is a `review-and-ship` audit angle, not a build step.

**`docs/craft/css.md` covers no easing, duration, or press feedback.** Motion work usually has no rule id to cite — say "no rule yet" rather than stretch one that means something else. MDN's View Transition API docs own browser mechanics.

---

## Constructing motion


# Animate

Own motion construction inside an approved implementation. Motion must explain state, preserve continuity, acknowledge input, or direct attention. Decoration alone does not qualify.

This operation inherits mutation authority from `build`. Return through `shape` when purpose or interaction behavior is unresolved. `review-and-ship` owns fixed-change review.

## Project authority

Read the accepted PLAN seam, current component and styles, `docs/craft/README.md`, `docs/craft/css.md`, `docs/craft/css/platform-behavior.md`, `docs/craft/phoenix-liveview.md`, and `docs/craft/dripfeed.md` when a settled motion decision may apply.

No button or component motion decisions are on record yet — there is no frontend. When the admin surface is built, record each decision here as it is made rather than inferring one from another project's conventions.

<!-- route-contract-v1:motion -->
| Condition | Meaning | Exact skill target | Guard |
| --- | --- | --- | --- |
| `accessibility` | Motion touches focus, keyboard, timing, reduced motion, zoom, or feedback equivalence | [accessibility.md](accessibility.md) | `reference` |
| `view-transition` | Approved design needs same- or cross-document snapshot mechanics | [view transitions](#view-transitions) | `reference` |
| `purpose-unclear` | Nobody approved the motion's purpose or interaction behavior | `shape` | `redirect` |
<!-- /route-contract-v1 -->

Read [physical motion principles](#physical-motion) for gesture, velocity, spatial origin, resistance, or direct manipulation; [motion review](#motion-review) before verification; [recipes](#recipes) only when its named pattern matches the approved interaction.

## Construction sequence

1. Name the motion's user-facing purpose and the static feedback that survives without it. If neither is concrete, do not animate.
2. Identify trigger, initial and target state, exit or reversal, frequency, spatial origin, interruption, and the state owner. Animation completion never owns business correctness.
3. Inspect existing tokens, CSS ownership, LiveView patch behavior, and deliberate no-motion decisions before adding declarations.
4. Choose the cheapest platform seam that preserves behavior:
- CSS transition for retriggerable state changes;
- discrete transition or `@starting-style` for supported entry/exit presentation;
- keyframes only for autonomous, non-retriggered sequences whose restart semantics are intentional;
- View Transition API through [view transitions](#view-transitions) for snapshot continuity;
- Web Animations API or a small colocated LiveView hook for browser-only imperative control;
- server state for navigation, authorization, validation, recovery, or accessible-tree membership.
5. Use native CSS and existing project tooling. Do not add Motion, Framer Motion, React, Tailwind, or another npm dependency.
6. Name exact properties, start and target values, duration, delay, easing or spring behavior, and why they fit distance, frequency, information need, and interruption. Do not copy a universal curve or duration into unrelated interactions.
7. Prefer compositor-friendly transform and opacity where they express the design truthfully. Measure layout or paint work before replacing it; `will-change` follows evidence and goes after the transition when practical.
8. Retriggerable motion retargets from its current value. Preserve drag offset and release velocity; handle pointer capture, extra pointers, cancellation, and resize.
9. Design exit with entry. Dismissal cannot run longer without a stated reason, lose focus, or leave stale captured state after LiveView patch or navigation.
10. Under reduced motion, drop nonessential travel but keep state feedback and access. Gate hover behavior by pointer capability; never hide meaning in motion.

## Verification

Run the [motion review](#motion-review) inspection, then add focus restore, LiveView patch/reconnect, layout/paint cost, unavailable-API fallback, and behavior with animation disabled, as applicable.

Return purpose, exact motion specification, implementation seam, files changed, observed verification, feel-check result, reduced-motion equivalent, fallback, and residual uncertainty.

---

## Physical motion

# Physical Motion Principles

Load when motion must feel connected to touch, pointer, gesture, velocity, or spatial origin. These principles adapt guidance attributed to Apple's Human Interface Guidelines and Emil Kowalski's design-engineering writing; they are design criteria, not substitutes for current platform docs or project accessibility rules.

Purpose gate, seam choice, dependency ban, named values, compositor properties, retargeting, exit design, reduced motion, completion ownership: [constructing motion](#constructing-motion).

## Purpose Before Decoration

Remove motion when it only delays access, repeats often without new information, or competes with the task. Repeated interactions need shorter, quieter motion than first-run disclosure.

## Direct Manipulation

- Visual state follows input continuously during a drag or gesture. Delayed, pre-scripted movement breaks contact.
- A surface opened from a control should emerge from, and return toward, it when layout permits.
- Use distance and direction to show where content came from or went.
- Hand measured gesture velocity into settling motion. Do not restart from zero velocity at release.
- Resistance and rubber-banding mark a boundary; keep them proportional, reversible, and free of hidden state changes.

## Response and Interruption

- Acknowledge input in the next rendered frame. Heavy work may continue; the response cannot wait for it.
- Interactive motion must be interruptible, preserving position and velocity where the tool supports it.
- Keyframes restart from their declared origin and can snap when state reverses mid-flight.
- Exit deserves entry's care: preserve continuity.

## Timing and Curves

- Duration follows distance, frequency, and information need.
- Frequent micro-interactions usually finish quickly. Larger spatial transitions may run longer only while continuity stays useful.
- Match easing to mechanics: decelerate into a resting target, avoid decorative bounce on serious or repetitive actions.
- Test at full speed, slowed, and under rapid reversal. A curve elegant once may fail under interruption.

## Accessibility and Performance

- Reduced-motion feedback uses opacity, color, or immediate state change.
- Measure before blaming animation for a performance problem; inspect layout/paint work in browser tooling.
- Never let motion hide focus, reorder reading unexpectedly, or delay keyboard access.


---

## Motion review

# Motion Review

Use this checklist while constructing motion and as changed-surface evidence for `review-and-ship`. `review-and-ship` still owns fixed-artifact review; this reference creates no second reviewer.

These findings are the negative form of rules in [constructing motion](#constructing-motion) and [physical motion principles](#physical-motion).

## Blocking Findings

- Motion has no user-facing purpose.
- Entry or exit starts from an unrelated spatial origin.
- A retriggerable interaction uses keyframes and snaps on reversal.
- Gesture release discards current position or velocity.
- Exit is missing, much slower than entry, or uninterruptible.
- Reduced-motion users lose feedback or access to content.
- Focus, keyboard access, reading order, or hit targets regress.
- Layout or paint work causes measured jank where a compositor-safe design exists.
- Animation completion owns business state, or correctness depends on it.
- Duration, delay, stagger, spring, or easing values are unexplained magic numbers copied across unrelated interactions.

## Inspection

1. Exercise entry, exit, rapid open-close-open, repeated triggering, keyboard flow, resize, and navigation interruption.
2. Slow playback in browser animation tooling; inspect transform origin, discontinuities, unintended overlap, and final values.
3. Check computed styles and cascade ownership; several selectors must not fight over one animated value.
4. Test reduced-motion behavior and a low-performance profile.
5. Verify final DOM, focus, and state without relying on animation timing.

Report evidence, user consequence, and the smallest correction. Preference alone is not a finding.

---

## Recipes

# Motion Recipes

Construction patterns, not defaults. Load only the matching one, apply current project tokens and ownership, and name exact values for the approved interaction. `docs/craft/dripfeed.md` and accepted decisions outrank every recipe.

Every recipe sits under [constructing motion](#constructing-motion) and [physical motion principles](#physical-motion).

## Deliberate no-motion control

The button no-motion record lives in [constructing motion](#constructing-motion). Preserve it when adjacent work touches button CSS.

## Anchored disclosure

For a popover, menu, or disclosure whose origin matters:

- derive origin from its trigger when the platform/component exposes it;
- transition explicit opacity and transform values from a small offset or scale, never from nothing;
- keep semantic visibility, focus movement, and dismissal independent of animation;
- use a transition so rapid close/reopen retargets from the current value.

## Dialog or drawer

- Treat surface and backdrop as one state change while owning their properties independently.
- A centered dialog may use center origin; an edge drawer keeps its real spatial edge.
- Focus entry, containment, dismissal, and restoration must work without animation.
- A draggable drawer is a gesture problem: do not mix a canned duration with direct manipulation.

## Toast or transient status

- Use state-driven CSS transitions, not keyframes: a toast can be dismissed or replaced mid-motion.
- Important errors and actions stay available outside a disappearing toast.
- Stack reflow and exit must not jump remaining messages; measure layout and keep stable keys through LiveView patches.

## Disclosure height

- Prefer semantic platform disclosure when it fits.
- Height animation costs layout work. Keep the state independent, test dynamic content and resize, and use a supported intrinsic-size technique or measured browser seam only when the approved benefit earns it.
- Hidden content must leave focus and accessibility order correctly; clipping alone does not manage state.

## Sequenced entrance

Use stagger only when order communicates hierarchy on an infrequent surface. Keep every item available immediately to keyboard and assistive technology, cap total delay, and reject stagger for routine lists, tables, search results, or repeated navigation.

## Hold to confirm

Use only when `shape` approved hold duration as the destructive-action contract. Progress runs linear while held; release cancels promptly. Provide keyboard and assistive-technology equivalents, expose remaining progress, and never hide a simpler confirm/undo path when it is safer.

## Shared indicator

For a tab or selection indicator, animating one shared geometry or clipping one active layer can keep background and text state synchronized. Selection semantics and focus move immediately; animation follows the already-changed state.

## Drag to dismiss

- Ignore or deliberately handle extra pointers so switching fingers cannot jump the surface.
- Track distance, elapsed time, and release velocity; threshold and settling must match the approved interaction.
- Apply proportional resistance past a boundary without triggering hidden state.
- Cancel safely on lost capture, Escape, resize, navigation, and LiveView removal.
- Use a small colocated hook only for browser-owned gesture mechanics; the server still owns domain mutation.

## Programmatic motion without a dependency

Use the Web Animations API when CSS cannot coordinate the approved browser-only sequence. Keep semantic state outside the animation, retain the returned animation for interruption/cancellation, and verify fallback when the API is unavailable.

---

## View transitions


# View Transitions

Supply browser API mechanics to [constructing motion](#constructing-motion), which keeps the purpose, seam, value, retargeting, exit, and reduced-motion rules; [motion review](#motion-review) owns inspection. This reference does not decide whether motion belongs, set universal duration/easing policy, or authorize implementation.

View Transitions are progressive presentation. Navigation, mutation, focus, URL/history behavior, accessible-tree state, and LiveView reconnect must stay correct when the API is unsupported, skipped, interrupted, or disabled.

## Same-document transitions

`document.startViewTransition(update)` captures the old rendered state, runs the DOM-update callback, captures the new state, and exposes a `ViewTransition` lifecycle. Use it only when the browser-owned callback can surround the real state change without duplicating or racing server state.

The generated overlay exposes root, group, image-pair, old-snapshot, and new-snapshot pseudo-elements. CSS may style their explicit properties. Do not let the overlay hide focus or stay above interactive content afterward.

Use `view-transition-name` only where continuity matters. Names participating at the same time must be unique. Stable record identity can supply a name through a narrow dynamic style value; validate and escape that value rather than expose arbitrary input.

Transition types can distinguish approved variants when supported. Keep a baseline needing neither types nor active-transition selectors for correctness.

## Cross-document transitions

Same-origin cross-document navigation can opt in with `@view-transition { navigation: auto; }` in both documents. The browser still controls eligibility and lifecycle; redirects, reloads, visibility, support, or navigation source may skip the effect.

`pageswap` can adjust or skip an outbound transition before capture. `pagereveal` can adjust or skip the inbound one before its first rendered frame. Treat both as optional browser seams, clean up for back/forward cache behavior, and keep application state out of these events.

## Phoenix and LiveView constraints

- Prefer CSS and existing LiveView navigation behavior before adding a hook.
- A colocated hook may coordinate a same-document transition only when it can identify the exact DOM update and cancel safely on a later patch, reconnect, or removal.
- Never duplicate hidden old/new application content solely to manufacture snapshots.
- Keep names stable across the intended old/new pair and absent elsewhere. Repeated stream items need record identity, not positional indexes.
- Verify that snapshot capture exposes no sensitive or stale content and that the final DOM remains the only interactive state.

## Verification packet

Return support evidence for target browsers, same- versus cross-document mode, captured elements and unique names, old/new lifecycle, interruption and skip behavior, focus and history behavior, reduced-motion treatment from [constructing motion](#constructing-motion), LiveView patch/reconnect behavior, and no-API fallback.

The API keeps evolving: check current mechanics against the [W3C View Transitions specifications](https://www.w3.org/TR/css-view-transitions/all/) and [MDN API reference](https://developer.mozilla.org/en-US/docs/Web/API/View_Transition_API) before implementing.
