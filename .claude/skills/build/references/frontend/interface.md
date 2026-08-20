# Interface Craft

Deeper material loads only when needed: [accessibility.md](accessibility.md), [color.md](color.md), [typography.md](typography.md).

**FindMeAFlat deltas only.** None of `docs/craft/css.md`, `docs/craft/css/`, or `docs/craft/phoenix-liveview.md` exists yet, so there are no `CSS-00n` / `WEB-00n` ids to cite — treat this file as the rules. **The only planned UI is the authenticated admin console; users interact through Telegram alone.**

---

## Interface

# Better UI

Supply static visual-detail criteria to `shape` or `build`. Do not run a separate audit, mutate files, or prescribe motion. [motion.md](motion.md) owns every transition, gesture, entrance, exit, and animated icon.

Use shared FindMeAFlat components, native CSS, semantic tokens, and the ownership rules in `docs/craft/css.md`. A polished inconsistency is still an inconsistency.

## Surfaces

- Borders carry structure, separation, selection, and focus; shadows carry elevation, only where the interface needs depth.
- Nested corners should read as one construction: derive inner radius from outer radius and real inset, then inspect the render rather than applying one radius everywhere.
- Keep elevation and radius roles few and semantic. No tokens for one-off values, no decoration compensating weak grouping.
- Image outlines must stay visible over both the image and the surface behind it. Check light, dark, high-contrast, and transparent imagery.
- Preserve established component sizing and density; adjacent polish authorizes no resize of controls and no change to information hierarchy.

## Optical alignment

- Align by perceived mass when geometric centering displaces asymmetric icons, triangles, or mixed text/icon controls.
- Keep the correction local to its owner, small enough that reading and hit-area geometry stay truthful.
- Compare repeated controls together; one isolated adjustment may expose a larger icon or spacing inconsistency.

## Icons

- Reuse the installed shared icon path and component before adding SVG markup or another source.
- Icons inherit semantic color through `currentColor` unless a real multi-color meaning exists.
- Match icon optical weight and rendered size to nearby text and controls. Inspect at final size; source-box dimensions do not prove balance.
- Use a consistent outline/fill state contract. Never let the icon change alone communicate selection, success, warning, or failure.
- Mirror directional icons for RTL only when their meaning is spatial. Do not mirror universal symbols, media controls, brand marks, or text-direction-independent status.
- Icon-only controls still need the accessible name and target behavior owned by [accessibility.md](accessibility.md).

## Evidence

Return to the owning operation: shared component or token inspected, states and appearances compared, optical adjustment rationale, icon source/state behavior, and any unresolved subjective choice.

---

## Layout

# Better Layout

Supply perceptual layout criteria to `shape` or `build`. Do not run a separate audit, prescribe CSS architecture, or mutate files.

CSS mechanics and unit policy live in `docs/craft/css.md` and its routed guides. This reference explains what the composition must communicate.

## Structure

- Group related information by proximity and shared alignment before adding boxes, dividers, or decoration.
- Give primary, secondary, and destructive actions distinct position and weight; controls must not look like passive content.
- Align repeated items to shared edges so differences stay scannable. Correct icons and irregular shapes optically without breaking the structural grid.
- Make DOM, reading, focus, and visual order agree; reordering at one breakpoint must not create a false keyboard or assistive-technology path.
- Reveal hidden or overflow content with a visible affordance; clipping cannot be the only hint that more exists.
- Preserve breathing room between adjacent targets, and between controls and viewport or safe-area edges.

## Adaptation

- Start with intrinsic layout: content size, wrapping, flexible tracks, bounded widths. Add a breakpoint only where content demonstrates failure.
- A reusable component responds to its container; a page responds to document or environment constraints. Width is not evidence of pointer capability.
- Choose units by what should scale. Page rhythm, component proportion, text measure, and hairlines do not share one unit.
- Use logical properties for flow-relative layout; keep physical properties for physical effects only — coordinates, shadows, crops, gesture direction.
- Stress long German listing titles, compound street names, missing prices, absent addresses, `null` room counts, dense tables, narrow widths, and large text.
- Preserve important actions and context under overflow. Truncation needs a reachable full value; horizontal scroll needs a deliberate boundary and cue.

## Evidence

Return to the owning operation: user task, grouping and order inspected, supported width or container states, content stress cases, direction/zoom checks, and observed overflow or alignment failures.

---

## Typography

# Better Typography

Supply typography criteria to `shape` or `build`. Do not run a separate audit, choose interface copy, or mutate files.

Use project type roles, semantic HTML, native CSS, and unit intent from `docs/craft/css.md`. Do not introduce Tailwind utilities, a second font system, or mandatory platform smoothing.

Load only the matching detail: [font delivery, variable axes, and OpenType](typography.md#fonts-and-opentype) or [wrapping, truncation, and bidirectional text](typography.md#wrapping-and-bidi).

## Fonts and hierarchy

- Serve compressed web formats and only the weights, styles, scripts, and variable-font axes used. Define truthful fallbacks; avoid synthetic bold or italic that changes meaning or layout.
- Use a small semantic type-role system. Heading levels describe document structure; visual size may vary by role without lying about hierarchy.
- Set unitless line height by role. Body text needs room to scan; compact labels and display type go tighter only when tested.
- Adjust letter spacing sparingly and in context. Do not use tracking to compensate for a mismatched font or force uppercase legibility.
- Use tabular numerals for changing aligned values — fees, dates, counts, timing columns; keep proportional numerals for prose.

## Reading and wrapping

- Calibrate long-form measure against FindMeAFlat's fonts and languages; roughly 60–75 characters is a starting observation, not a universal width token.
- Use balanced wrapping for short headings, deliberate wrapping for prose where supported. Do not insert manual line breaks that fail under translation or resize.
- Truncate only when the full value stays reachable. Avoid truncating the only label, error, or distinguishing part of a listing title or address.
- Inputs stay large enough to avoid mobile browser zoom. Placeholder, caret, and selection colors must stay legible.
- Keep useful text selectable. Disable selection only on a proven gesture surface.

## Language and direction

- Set truthful language and direction metadata. Isolate mixed-direction identifiers, dates, URLs, and user content so surrounding punctuation does not reorder.
- Preserve natural source copy; let CSS handle wrapping and presentation. Follow project punctuation and voice, not generic typographic substitutions.
- Verify fallback glyphs, diacritics, long compounds, CJK text, RTL text, and numeric alignment wherever the surface can receive them.

## Evidence

Return to the owning operation: font files and roles inspected, weights and axes loaded, measure/wrapping cases, zoom/input behavior, truncation reachability, language/direction cases, and any rendering uncertainty.

---

## Color

# Better Colors

Supply color criteria to `shape` or `build`. Do not run a separate audit, own theme architecture, or mutate files.

Project color architecture lives in `docs/craft/css.md` and its architecture guide. FindMeAFlat uses native CSS and semantic roles; do not add Tailwind vocabulary or component-local theme branches.

Load only the matching detail: [color conversion](color.md#color-conversion), [contrast](color.md#accessibility-contrast), or [palette and gamut work](color.md#palette-generation).

## Color model

- Prefer OKLCH for authored palette work; lightness and chroma changes are easier to reason about perceptually. Preserve alpha during conversion and keep one notation.
- Keep stable palette primitives separate from semantic roles: canvas, ink, border, link, positive, warning, negative.
- Components consume semantic roles or narrow component inputs, never palette steps. A theme rebinds roles rather than restyling components.
- Use one role for one meaning even when two values happen to match today.

## Palette and gamut

- Build ramps with an intentional lightness progression. Adjust chroma near light and dark ends where the target gamut narrows; verify hue drift instead of assuming numeric consistency looks consistent.
- Provide an sRGB-safe baseline before progressive wide-gamut enhancement. Test high-chroma values on the target display gamut and clamp deliberately.
- Design dark appearance as its own semantic mapping; mechanical inversion does not preserve hierarchy or contrast.
- Keep `color-scheme` aligned with the active appearance so native controls participate.

## Meaning and contrast

- Color may reinforce status but cannot be its only signal. Pair it with text, iconography, shape, or another persistent cue.
- Color meaning is locale-dependent. Verify every shipped locale before treating hue as semantic in finance, status, and alert roles. Bind gain/loss and other load-bearing roles through locale-aware tokens when audience conventions reverse them; Chinese financial interfaces commonly use red for gains and green for losses.
- Measure every foreground against its rendered background: translucent and layered surfaces, focus indicators, disabled states, both appearances, forced colors, interaction states.
- Repairing contrast preserves the semantic hue where possible: adjust lightness and chroma, then remeasure. One passing pair does not prove every theme or state.
- Colors derived from `color-mix()` still require contrast and gamut checks.

## Evidence

Return to the owning operation: tokens or selectors inspected, rendered foreground/background pairs, method and result, gamut fallback, theme states checked, and any unresolved display assumption.

---

## Accessibility

# Better Accessibility

Supply accessibility criteria to `shape` or `build`. Do not run a separate audit, choose product behavior, or mutate files.

Read the applicable project standards, `docs/craft/phoenix-liveview.md`, and the relevant CSS guide first. Prefer established shared FindMeAFlat components; a raw control or custom widget needs a concrete reason.

Load only the matching detail: [focus and keyboard](accessibility.md#focus-and-keyboard), [forms](accessibility.md#forms), [screen readers and dynamic announcements](accessibility.md#screen-readers), [hit areas](accessibility.md#hit-areas), or [motion, timing, zoom, and reflow](accessibility.md#motion-and-zoom).

## Semantics and names

- Use native elements for their behavior: button for action, link with `href` for navigation, form controls with associated labels, headings and landmarks for document structure.
- Use ARIA only to complete a semantic contract the platform cannot express. Never add a role that contradicts the element.
- Every control needs a stable accessible name. Visible text should participate in it; decorative icons hide from assistive technology.
- Alternative text describes an image's purpose in context. Decorative images use empty alt text.
- DOM and accessibility-tree order must match reading, focus, and visual order. CSS reordering cannot repair false source order.

## Keyboard and focus

- Preserve visible `:focus-visible` indication with adequate contrast. Never remove an outline without an equivalent.
- Use normal tab order; avoid positive `tabindex`. Custom composite widgets implement the established keyboard pattern completely, or use a native/shared component.
- Dialogs and modal surfaces move focus deliberately, contain it while active, close through an available keyboard path, and restore focus to a sensible origin.
- A pointer-only hover, drag, or gesture always has keyboard and touch alternatives. Hit areas and spacing must support imprecise input without changing the visual target's meaning.

## Forms and dynamic state

- Keep labels present; placeholders are examples, not labels. Associate instructions and errors with their fields.
- Do not validate noisily on every keystroke. Validate at a meaningful boundary, preserve entered values, announce new errors, and focus or summarize them per the shared form pattern.
- A disabled control must stay understandable. When users need the reason or an action, use an explanatory state, not an undiscoverable disabled element.
- Announce meaningful asynchronous status once with the right live-region semantics. Transient toasts must not be the sole location of errors or required actions.
- Loading, reconnect, retry, and completion state stay perceivable without color, animation, or timing.

## Display preferences

- Interfaces must reflow under browser zoom and larger text without losing content, actions, labels, or focus.
- Use logical properties and preserve language/direction metadata for mixed-direction text.
- Reduced motion removes nonessential travel and keeps feedback through immediate state, opacity, color, icon, or text. It must not remove content or delay access.
- Autoplaying or timed content needs an accessible pause, extension, or dismissal policy matching its consequence.
- Forced-colors and increased-contrast modes retain control boundaries, focus, and state distinctions.

## Evidence

Verify keyboard paths, focus entry/exit, accessible names and descriptions, error announcements, zoom/reflow, touch behavior, reduced motion, and LiveView patch/reconnect behavior. Return observed evidence and remaining uncertainty to the owning operation.

---

## Copy

# Better Writing

Supply language criteria to `shape` or `build`. Do not run a separate audit, choose product behavior, or mutate files.

## Voice

- Read nearby product copy and domain documentation first. Use the language of flat hunting and German tenancy, not Ash, Phoenix, jobs, resources, or internal status codes.
- Prefer short, direct sentences and familiar words. Remove exclamation, cuteness, blame, filler, colloquialisms, and em dashes.
- Address the user only when it clarifies responsibility. Prefer active voice; name FindMeAFlat when the system acted.
- Keep one term per domain concept. A shared collaboration container is a `Space`; do not casually rename it a team, workspace, group, or organization.

## Actions and navigation

- Label consequential controls with a specific verb and object: `Save draft`, `Invite member`, `Delete project`. Avoid `OK`, bare `Yes`/`No`, `Submit`, or clever slogans.
- Confirmation labels repeat the consequence. Cancel labels state the safe alternative when `Cancel` would be ambiguous.
- Link text describes its destination or revealed content. Do not use `Click here` or expose raw URLs as prose.
- Settings describe the enabled state so label, current value, and consequence agree.

## States and recovery

- An error states the event, preserves what remains safe, and gives the next realistic action. Do not promise a retry will work when the cause is unknown.
- Put field errors beside their field, phrased as repair instructions. Keep the user's value unless security or correctness requires clearing it.
- An empty state explains why nothing is present when that is not obvious, then names one useful next action. Do not celebrate emptiness or invent marketing copy.
- Loading and success messages identify meaningful work or outcome; omit narration when the changed interface already shows success.
- Placeholders show format or example data. They never replace labels or instructions.
- Sensitive and authentication failures avoid account enumeration, secret values, and internal security detail while still offering recovery.

## Verification

Return complete replacements in context, not isolated fragments. Check interpolation, pluralization, dates and currencies, long names, narrow-width wrapping, screen-reader announcement, and consistency with the full flow. Report uncertainty when the behavior or domain term is not settled.
