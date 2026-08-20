# Prototyping

**FindMeAFlat deltas only.** Dead-view mechanics belong to hexdocs `Phoenix.LiveView`. No `docs/craft/phoenix-liveview.md` exists yet. **A prototype here is more often a parser against a saved HTML fixture than a screen.**

---

## Choosing and running the experiment


# Prototype

Build the smallest disposable artifact that answers one named question. A prototype produces evidence, not production code, and never silently becomes implementation.

## Experiment choice

- Business rules, state transitions, API shape, or data representation → [LOGIC.md](#logic-experiments).
- Interface structure, interaction behavior, or competing visual hierarchies → [UI.md](#interface-experiments).

When the question mixes both, isolate the uncertain seam and pick one branch first. State the assumption when evidence cannot separate them.

## Authority and location

Default to a disposable directory under `tmp/` or the system temp directory. A prototype request authorizes that artifact alone — not production code, dependencies, routes, issue trackers, branches, commits, or remote systems.

Prototype code stays under `tmp/`. Editing a repository file first needs Chris's quoted instruction, a cleanup condition recorded in `CONCEPT.md`, a prototype marking, and an existing development-only or Storybook boundary around it.

Use FindMeAFlat's existing Elixir, Phoenix LiveView, HEEx, CSS, and test tooling. Add no second runtime, package manager, UI framework, motion package, database, or persistent service for a prototype.

## Procedure

1. Write one falsifiable question and the observation that answers it.
2. Read only the domain, Craft, ADR, and code context that question needs.
3. Choose the cheapest representative cases, including the boundary most likely to overturn the idea.
4. Build one-command, local, reversible evidence. Stub mutations and external services unless they are the exact uncertainty under test and separately authorized.
5. Let the user exercise the artifact when judgment is experiential; otherwise run the cases and record observations.
6. State `supported`, `rejected`, or `inconclusive`, with the reason observed and the uncertainty left.
7. Record the answer in the already-authorized proposal or plan when one exists. Create no issue, branch, commit, or production implementation without separate authority.
8. Remove the artifact once its evidence is captured. Stop and ask when cleanup would delete a user-authored or shared artifact.

## Exit

Return the question, artifact location, exact run command, observations, verdict, remaining uncertainty, and cleanup status. An inconclusive prototype is valid when it narrows the next question.

---

## Logic experiments

# Logic Prototype

Take this branch for uncertainty about a business rule, state transition, action boundary, API shape, or data representation.

## Shape

- Model the smallest domain state and event set that exposes the uncertainty.
- Prefer a pure Elixir function, reducer, or explicit transition table. Keep terminal and display code outside the model.
- Reuse project domain terms. Invent no production names before the experiment supports them.
- Show full relevant state before and after each event, so impossible transitions and hidden derived state surface.
- Include the ordinary path, a boundary case, and the realistic failure or out-of-order case most likely to reject the model.

Use an existing Mix command when the experiment needs compiled project code; otherwise a self-contained Elixir script in a disposable directory. Do not connect to FindMeAFlat's database by default. When persistence is the question, use sandboxed test data or an explicitly named disposable store, and report its cleanup.

## Evaluation

Record for every case:

- starting state;
- event or input;
- resulting state or error;
- invariant tested;
- whether the observation supports or rejects the proposed model.

Do not keep the prototype module merely because its shape looks reusable. Production code still needs `build`, tests, error handling, and the accepted architecture.

---

## Interface experiments

# UI Prototype

Take this branch for uncertainty about interface structure, information hierarchy, interaction behavior, or competing affordances.

## Shape

Default to three structurally distinct variants. They must disagree about hierarchy, layout, or primary action; color-only and copy-only variations answer no design question.

Judge them with representative FindMeAFlat content at realistic density. Keep the surrounding application shell when it affects the decision. Use existing shared components, semantic HTML, HEEx, native CSS, and project tokens. Add no React, Tailwind, JavaScript component libraries, or npm motion dependencies.

For a disposable artifact, use static HTML/CSS or an isolated Phoenix component example under `tmp/`. When the question needs live application context and repository mutation is authorized, prefer an existing Storybook or development-only surface over a new application route. Keep actions read-only or stubbed.

## Comparison

Give every variant the same content and constraints. Compare:

- task path and primary action;
- reading and focus order;
- narrow and wide layout behavior;
- keyboard and assistive-technology semantics;
- empty, loading, error, and success feedback relevant to the question;
- what each makes easier and what it makes harder.

Keep useful switching controls visibly outside the proposed interface, keyboard accessible, and development-only. A query parameter is optional evidence plumbing, not a required product pattern.

## Evaluation

Return variant names, one meaningful difference per variant, observed preference or failure, and the winning principle. A winner stays prototype evidence: rebuild the accepted behavior through `build`; never promote prototype code unchanged.
