# Accessibility — detail

Loaded from [interface.md](interface.md) when a change touches semantics, focus, keyboard paths, forms, dynamic announcements, hit areas, zoom, or reduced motion.

**FindMeAFlat deltas only.** WCAG 2.2 and the MDN ARIA docs own general behaviour. Scope note: the only planned UI is the admin console, so accessibility work here is single-operator rather than public-facing.

---

## focus-and-keyboard

# Focus and Keyboard

## Global shortcuts

Document-level shortcuts never fire while focus sits in `input`, `textarea`, `select`, or an editable element such as `[contenteditable]`. Check the composed path so controls inside components get the same protection. Show discoverable `kbd` hints only where the shortcut works; hide pointer-inapplicable hints on touch-only layouts.

## Focus evidence

Prefer the browser focus indicator. Custom styling uses the verified project token; inspect the indicator's full perimeter against every adjacent fill, image, gradient, hover, selected, and disabled state. Preserve system colors under forced-colors; do not freeze authored colors with `forced-color-adjust: none` without evidence.

Use `:focus-visible` for keyboard-visible treatment and `:focus-within` only when the owning wrapper needs a group state. Never remove outlines without an equivalent.

Repeated chrome needs a first-focusable skip link to the primary landmark. Account for sticky headers with the target's scroll margin.

## Focus order and composite widgets

- `tabindex="0"` joins natural order only for a justified custom focus target.
- `tabindex="-1"` permits deliberate programmatic focus without adding a Tab stop.
- Positive `tabindex` is forbidden; repair source order.
- Composite widgets use one Tab stop and the appropriate arrow-key model. A role promises its complete behavior.

| Widget | Expected keyboard shape |
| --- | --- |
| Dialog | Tab/Shift+Tab stay inside; Escape closes when dismissal is safe |
| Tabs | Arrows move among tabs; Home/End reach bounds; Tab enters/leaves panel; activation is automatic only when instant |
| Menu button | Enter/Space opens; arrows navigate; Escape closes and restores trigger focus |
| Disclosure | Native/shared button exposes `aria-expanded`; Enter and Space toggle |
| Combobox | Shared component owns input/list navigation, acceptance, and Escape behavior |
| Radio/listbox | One Tab stop; arrows change focused or selected option per its pattern |

Prefer native `<dialog>` or the established shared dialog. On open, move focus by content and consequence; destructive confirmation normally starts on the safe action. On close, restore the trigger or nearest logical successor. Background content cannot stay focusable or appear as active modal content.

Update the document title after LiveView navigation, and move focus only where the current project navigation pattern requires it. Preserve browser history and scroll behavior; do not write generic SPA focus code around server navigation without a tested seam.

---

## forms

# Accessible Forms

Use shared FindMeAFlat field and control components plus AshPhoenix form state. Preserve their error, value, label, and focus contracts before extending them.

## Related controls

Give every checkbox or radio its own label and the related set one programmatic group name. Prefer `fieldset` with `legend`; use a correctly named ARIA group only when native grouping cannot represent the interaction. Option labels such as "Open" and "Closed" do not replace the group question.

## Disabled states

Native `disabled` handles unavailable controls: it drops the control from tab order, suppresses activation, applies `:disabled`, and omits applicable form values. Use `aria-disabled="true"` only when a discoverable focus stop is intentional or a custom control cannot use native disabled. ARIA alone changes no behavior or style: block pointer and keyboard activation in the handler, prevent submission where applicable, add explicit styling including forced colors, and explain nearby why the action is unavailable. Never combine `disabled` and `aria-disabled` on one element. Keep submit available for validation and recovery; do not disable it because current input is invalid.

## Field contract

- Every control has a programmatic visible label; placeholders supply examples only.
- `required` semantics and visible explanation agree. Checkbox/radio labels share the control's hit target.
- Inline errors set the field's invalid state and attach through the established description/error IDs. Text or icon accompanies color.
- Submission may reveal incomplete input; do not disable the submit control merely to hide validation. Once a request begins, prevent duplicate submission while keeping the action label and a perceivable busy state.
- Preserve values and focus through validation, LiveView patches, reconnect, and failed submission. Focus the first invalid field or the established error summary, not both.

## Input assistance

Use truthful `type`, `autocomplete`, and `inputmode` values. Common autocomplete tokens include `name`, `email`, `tel`, address parts, `username`, `current-password`, `new-password`, and `one-time-code`; prefix a section where repeated address/payment groups require it.

Use text semantics plus numeric or decimal input mode for codes, card-like identifiers, and money when numeric steppers are false. Disable spellcheck for identifiers where appropriate. Keep real forms compatible with password managers and one-time-code autofill.

Never block paste, browser zoom, password managers, or text expansion. Normalize and validate at the domain boundary; do not filter characters during typing unless the interaction is an approved structured control.

Announce form-level failures separately only when focus or field descriptions do not already announce them. Sensitive failures must avoid account enumeration and secret disclosure while still offering recovery.

---

## hit-areas

# Hit Areas

Separate conformance floor from usability preference. WCAG 2.2 target size uses a 24 by 24 CSS-pixel baseline with defined spacing, equivalent-control, inline, user-agent, and essential exceptions. Larger touch targets around 44 CSS pixels are a product goal, not an automatic failure threshold.

Choose implementation units through project unit intent; conformance measurement still uses rendered CSS pixels. The whole visible control and its label should activate one target without dead zones.

Prefer giving the shared component real box size. When visual size must stay smaller, an owner pseudo-element may extend the target without overlapping another. Put it on a reliable wrapper or control, not a replaced input. Overlapping hit areas create ambiguous activation and must be repaired.

Verify rendered target and spacing, zoom, touch, pointer precision, label activation, and nearby controls. Do not use a target-size exception without naming and demonstrating it.

---

## motion-and-zoom

# Motion, Timing, Zoom, and Reflow

Reduced motion removes vestibular travel and autonomous decoration but keeps necessary state feedback. Prefer motion-safe construction for new work; do not add a global near-zero-duration reset that changes application timing or completion behavior. Loading/progress may stay when it creates no harmful travel; immediate color, icon, or text state should remain.

Anything moving, blinking, or updating automatically long enough to distract needs an appropriate pause, stop, hide, or extension mechanism. Important errors, actions, and undo cannot live only in timed content. Autoplaying media starts without sound and exposes controls when allowed at all.

Verify text resize to 200 percent and reflow equivalent to a 320 CSS-pixel viewport without losing content or two-dimensional navigation, except two-dimensional content such as a table or map in its own deliberate region. Fixed-height text containers fail often.

Never block browser zoom. Inputs must avoid mobile auto-zoom through legible text size, not viewport restrictions. Use the unit rules in `docs/craft/css/units-and-responsive-design.md`: reader-relative values scale with reader settings, physical hairlines stay physical, and breakpoints follow content failure rather than device labels.

---

## screen-readers

# Screen Readers and Dynamic Announcements

Use the existing project visually-hidden utility. It must stay in the accessibility tree, avoid zero-size loss, and become visible when used for focusable skip links. Do not create another utility class casually.

Choose one announcement seam:

1. Focus moved to the changed content: no additional announcement.
2. State belongs to a control: use its description or error relationship.
3. Non-urgent asynchronous status: use a stable polite status region.
4. Urgent failure not tied to a control: use an assertive alert sparingly.

For repeated polite updates, mount the empty region before changing its text; inserting the region with its first message is announced inconsistently. Keep messages short and atomic. Do not move focus to a toast, and never put the only recovery action in auto-dismissing content.

Use `aria-busy` on the region whose content is updating and announce a meaningful result, not every transport phase. LiveView patches must preserve stable IDs and must not replay old status accidentally.

Alternative text follows purpose: decorative or redundant images take empty alt text; informative images describe added meaning; functional images name the action; complex visuals get nearby data or explanation. Decorative SVG is hidden; a meaningful standalone SVG takes image semantics and a stable name. A focused element can never sit inside an `aria-hidden` subtree.

Prerecorded video needs captions and audio needs an equivalent transcript when content requires it. Autoplay with sound is not acceptable.
