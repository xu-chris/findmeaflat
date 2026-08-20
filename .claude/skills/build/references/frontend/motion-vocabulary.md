# Motion Vocabulary

Lookup only: name or disambiguate a motion effect from a vague description. It does not recommend or implement.

General behaviour is owned by the MDN animation and transition docs.

# Animation Vocabulary

Turn a vague description of a motion or effect into the precise term, so the user knows what to ask for.

A vocabulary match is not design approval. `shape` decides whether motion is useful; [motion.md](motion.md) constructs approved motion.

## Quick Start

The user describes an effect loosely. Return the matching term(s) in this format:

```
**Stagger** — Animate several items one after another with a small delay, creating a cascade.
```

If several terms fit, list the best match first, then 1–2 alternates with a one-line note on how they differ.

## Instructions

1. **Read for intent, not keywords.** Users describe what they *see* or *feel* ("springy", "slides off", "draws itself in"), not the technical name. Map the sensation to the glossary.
2. **Use the glossary definition.** Paraphrase only to fit the user's context; do not turn a term into project policy.
3. **Disambiguate close terms.** When two compete (*Clip-path* vs *Mask*, *Pop in* vs *Bounce*, *Shared element transition* vs *Layout animation*), contrast them so the user can pick.
4. **When nothing matches exactly,** name the closest term and say plainly it's an approximation, or describe the effect in the glossary's vocabulary (e.g. "that's a *stagger* of *scale-in* entrances").
5. **Stay within this glossary.** If a term isn't here, say so rather than inventing one — you may still explain the concept using these words.
6. **Keep it tight.** A naming question wants a name, not an essay. Lead with the term; expand only if asked.

## Examples

**Example 1 — feel-based** User: "What's it called when a popover seems to grow out of the button you clicked instead of from its middle?" Output:
```
**Origin-aware animation** — An element animates out of its trigger: a popover growing from the button that opened it, not from its own center, the CSS default.
```

**Example 2 — disambiguation** User: "The thing where one image turns into another image." Output:
```
**Morph** — One shape smoothly turns into another, e.g. Dynamic Island.

Close alternates:
- **Crossfade** — if they fade over each other in the same spot.
- **Shared element transition** — if an element travels and transforms from one position into another.
```

**Example 3 — physics feel** User: "That iOS scroll where it resists and snaps back when you pull too far." Output:
```
**Rubber-banding** — Resistance and snap-back when you drag past a boundary (the iOS overscroll feel).
```

## Glossary

_A curated snapshot mirroring the project's `/vocabulary` page; keep the two in sync when either changes._

### Entrances & Exits — how elements appear and disappear
- **Fade in / Fade out** — Opacity change brings an element in or out.
- **Slide in** — Element enters from off-screen: left, right, top, or bottom.
- **Scale in** — Element grows to full size as it appears, often with a fade.
- **Pop in** — Element appears with a slight overshoot, bouncing into place.
- **Reveal** — Content uncovers gradually, usually via clip-path or mask.
- **Enter / Exit** — The animation an element plays when added to or removed from the screen.

### Sequencing & Timing — coordinating multiple elements or moments
- **Keyframes** — Defined points in an animation (0%, 50%, 100%); the browser fills the gaps.
- **Interpolation / Tween** — In-between frames from start value to end value, making motion continuous.
- **Stagger** — Animate several items one after another with a small delay, creating a cascade.
- **Orchestration** — Timing several animations so they feel like one coordinated motion.
- **Delay** — Time before an animation starts.
- **Duration** — How long an animation takes.
- **Fill mode** — Whether an element keeps its first or last frame's styles before or after the animation (e.g. forwards).
- **Stepped animation** — Animation divided into discrete steps, like a countdown timer.

### Movement & Transforms — changing an element's position, size, or angle
- **Translate** — Move an element along the X or Y axis.
- **Scale** — Make an element bigger or smaller.
- **Rotate** — Spin an element around a point.
- **Skew** — Slant an element along the X or Y axis, shearing it out of its rectangle.
- **3D tilt / Flip** — Rotate in 3D space (rotateX / rotateY) for depth.
- **Perspective** — How strong the 3D effect looks; lower values exaggerate depth, as if the viewer sits closer.
- **Transform origin** — The anchor point a scale or rotation grows or spins from.
- **Origin-aware animation** — An element animates out of its trigger: a popover growing from the button that opened it, not from its own center, the CSS default.

### Transitions Between States — connecting one state, view, or element to another
- **Crossfade** — One element fades out as another fades in, in the same spot.
- **Continuity transition** — A change that keeps the user oriented by connecting before and after, like growing and shrinking the same rectangle.
- **Morph** — One shape smoothly turns into another, e.g. Dynamic Island.
- **Shared element transition** — An element travels and transforms from one position into another, like a thumbnail expanding into a card.
- **Layout animation** — An element animates to its new size or position instead of snapping.
- **Accordion / Collapse** — A section expands and collapses its height to show or hide content.
- **Direction-aware transition** — Content slides one way forward and the opposite way back, giving navigation direction.

### Scroll — motion tied to scrolling or navigating between views
- **Scroll reveal** — Elements fade or slide into place as they enter the viewport.
- **Scroll-driven animation** — Animation progress tied directly to scroll position.
- **Parallax** — Background and foreground scroll at different speeds, creating depth.
- **Page transition** — Animation played when navigating between pages or routes.
- **View transition** — The browser morphs between two states or pages, connecting shared elements.

### Feedback & Interaction — responding to the user's actions
- **Hover effect** — Visual change when the cursor moves over an element.
- **Press / Tap feedback** — A subtle scale-down on click, so it feels physical.
- **Hold to confirm** — A progress effect filling while the user holds a button.
- **Drag** — Moving an element by grabbing it, often with momentum on release.
- **Drag to reorder** — Dragging list items to rearrange them while the others shift to make room.
- **Swipe to dismiss** — Dragging an element off-screen to close it, like a drawer or toast.
- **Rubber-banding** — Resistance and snap-back when you drag past a boundary (the iOS overscroll feel).
- **Shake / Wiggle** — A quick side-to-side jitter signaling an error or rejected input.
- **Ripple** — A circle expanding from the tap point, confirming the press.

### Easing — how speed changes over an animation
- **Easing** — The rate at which an animation speeds up or slows down.
- **Ease-out** — Starts fast, ends slow. The default for most UI and anything responding to the user.
- **Ease-in** — Starts slow, ends fast. Usually avoided; can feel sluggish.
- **Ease-in-out** — Slow, fast, slow. Good for on-screen elements moving from A to B.
- **Linear** — Constant speed. Avoid for UI; reserve for spinners or marquees.
- **Cubic-bezier** — A custom easing curve for precise control.
- **Asymmetric easing** — A curve that accelerates and decelerates at different rates. Feels more alive than a symmetric one.

### Spring Animations — physics-based motion as an alternative to fixed-duration easing
- **Spring** — Motion driven by physics (tension, mass, damping) rather than a set duration.
- **Stiffness / Tension** — How strongly the spring pulls toward its target. Higher feels snappier.
- **Damping** — How quickly a spring settles. Lower damping means more bounce and oscillation.
- **Mass** — How heavy the element feels. More mass moves slower and more sluggishly.
- **Bounce** — A spring that overshoots and settles, adding playfulness.
- **Perceptual duration** — How long a spring feels finished while it micro-settles underneath.
- **Momentum** — Motion carrying velocity, especially after a drag or interruption.
- **Velocity** — How fast and in which direction an element moves. A spring carries it into the next animation when interrupted, so a flicked element keeps its speed.
- **Interruptible animation** — An animation redirected mid-flight instead of finishing first.

### Looping & Ambient Motion — animations that run on their own
- **Marquee** — Text or content scrolling continuously in a loop.
- **Loop** — An animation that repeats, a set number of times or infinitely.
- **Alternate (yoyo)** — A loop that plays forward then reverses each iteration instead of jumping back to the start.
- **Orbit** — An element circling another in a continuous path.
- **Pulse** — A gentle repeating scale or opacity change to draw attention.
- **Float** — A gentle, continuous up-and-down drift making a static element feel alive and weightless.
- **Idle animation** — Subtle motion while an element sits waiting for interaction.

### Polish & Effects — the small touches that separate good from great
- **Blur** — A blur filter softening an element or masking tiny imperfections.
- **Clip-path** — Clipping an element to a shape, for reveals, masks, and before/after sliders.
- **Mask** — Hiding or revealing parts of an element with a shape or gradient — like clip-path, but with soft, fadeable edges.
- **Before / after slider** — A draggable divider wiping between two overlaid images to compare them.
- **Line drawing** — An SVG path drawing itself in, like an invisible pen tracing it.
- **Text morph** — Text animating character by character when it changes, drawing attention to the new value.
- **Skeleton / Shimmer** — A placeholder with a moving sheen shown while content loads.
- **Number ticker** — Digits rolling or counting up to a value.
- **Tabular numbers** — Fixed-width digits so numbers don't shift as they change. Essential for tickers, timers, and counters.
- **Typewriter** — Text appearing one character at a time, as if typed.

### Performance — what keeps motion smooth instead of stuttering
- **Frame rate (FPS)** — Frames drawn per second. 60fps is the baseline for smooth motion; 120fps on newer displays.
- **Jank** — Visible stutter when the browser drops frames it can't keep up with.
- **Dropped frame** — A frame the browser missed its deadline to draw, causing a tiny hitch.
- **Compositing** — The GPU moves or fades an element on its own layer without redoing layout or paint.
- **will-change** — A CSS hint that an element is about to animate, so the browser promotes it to its own layer early.
- **Layout thrashing** — Animating width, height, top, or left forces the browser to recalculate layout every frame, causing jank.

### Principles to Know — concepts that guide when and how to animate
- **Purposeful animation** — Motion serves a function — orient, give feedback, show relationships — not decoration.
- **Anticipation** — A small wind-up in the opposite direction before a move, hinting at what comes.
- **Follow-through** — Parts of an element keep moving and settle after the main motion stops, adding weight.
- **Squash & stretch** — Deforming an element as it moves to convey weight, speed, and flexibility.
- **Perceived performance** — The right animation makes an interface feel faster, even when it isn't.
- **Frequency of use** — The more often a user sees an animation, the shorter and subtler it should be.
- **Spatial consistency** — Animating so an element keeps its identity and position across states, so users never lose track of it.
- **Hardware acceleration** — Animating transform and opacity lets the GPU keep motion smooth.
- **Reduced motion** — Respecting the user's prefers-reduced-motion setting by toning down or removing motion.
