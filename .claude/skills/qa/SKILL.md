---
name: qa
description: Use when built work has never been opened in the running app, when a UI slice needs exercising at real viewport widths, or when a change reads correct and nobody has clicked it. Runs before or alongside review; it files what breaks as issues and never diagnoses or repairs.
---

# QA

**Stance: moderated.** The unattended sweep runs to completion; the human stage stops and waits for Chris — §5.

Undefined terms — proposal card, Green/Yellow/Red, stance, the `Decided:` rule: [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` start at the repository root, not this file.**

**A personal skill named `qa` also lives in Chris's global setup.** Per `CLAUDE.md` the project skill wins for FindMeAFlat work. Name this one by its path when the host offers both.

> **This harness reviews code well and never opens the app.**

A combo box worked on desktop, broke inside the mobile navigation, passed review, and shipped to production. Code review cannot catch that class of defect. Only the running application can.

**Test output is not QA.** `mix test`, `Phoenix.LiveViewTest`, a green CI run, and a clean compile all read a different copy of the app. This skill has one input: the running application in a browser. A run that produced no `browser_eval` result produced no QA.

## Entry gate

QA runs on implemented vertical slices. **A slice here is one `PLAN.md` entry, or one job the accepted `### Bet` names for a Green card** — take them from `docs/proposals/3-bet-go/NNN-slug/`. Nothing implemented, no entry — route to `build`.

**QA finds defects and stops there: never explain a root cause, never edit application code, never open a pull request.** `diagnose-bug` owns the cause; `fix-bug` owns the repair.

## 1. Prerequisites

Three checks, in order. **A failure at any one ends the run.** Name the check that failed, report the pass as `blocked`, and stop. A QA pass that could not open the app is not a clean QA pass, and "no defects found" is a false statement about a browser you never reached. **`build`'s server-down fallback does not carry here** — `mix compile --warnings-as-errors` and `mix test` verify a build, and this skill verifies a running app.

| | Check | How |
| --- | --- | --- |
| 1 | The dev server answers | `mcp__tidewave__project_eval` returns a result |
| 2 | It is **this worktree's** server | the identity probe below |
| 3 | A browser is attached | `mcp__tidewave__browser_eval` with `action: "help"` returns the API |

**Liveness is not identity.** Run the probe, then compare its path against the checkout you are working in and its port against `.claude/worktree.md`, which every provisioned worktree carries. A plain checkout has no such file and defaults to 4000:

```elixir
{File.cwd!(), Application.get_env(:find_me_a_flat, FindMeAFlatWeb.Endpoint)[:http][:port]}
```

A path or a port from another checkout means Tidewave answers a different server, and every result you report describes code you did not change. **Stop even when the two branches look identical** — you would be inferring what the other server runs. This skill's own authoring run hit that: the probe returned the main repository and port 4000 while the worktree expected 9862, with nothing listening on 9862. Check 2 exists because check 1 passes anyway.

Check 3 fails with `No browser is connected to the Tidewave control page`. Only a human can fix it, by opening `http://localhost:<port>/tidewave`. Ask for that and stop; a browserless run has no second route.

**Call `help` before any other action.** Tidewave's own tool text requires it and the action names move between versions. Never call an action `help` did not list.

Recorded browser gotchas — portaled menus and dialogs, locators outliving a focus-sensitive menu, sequential `browser.click` calls in one evaluation: [../build/references/testing.md](../build/references/testing.md). Read it before driving anything with a menu, dialog, or overlay.

## 2. Slice inventory

List every vertical slice the work implemented and the entry URL for each. A slice with no reachable URL stays on the list; say why it has none.

Reach each slice the way a user does, by navigating from the app's own entry point. **Never jump straight to a deep URL.** The motivating failure lived in the navigation rather than the page, and a deep link routes around exactly the surface that broke.

## 3. Viewport sweep

**Four widths, every slice, no exceptions.** Each exercises a branch this stylesheet has.

| Width | Why this one |
| ---: | --- |
| 320 px | the reflow floor `docs/craft/css/units-and-responsive-design.md` requires |
| 640 px | `40rem`, the stylesheet's most-used boundary, where the mobile branch flips to the desktop one |
| 768 px | tablet: no media branch changes here, and container queries recompose anyway |
| 1280 px | `80rem`, the widest branch |

**Name the widths you exercised beside every slice.** A slice reported without its four widths is untested at the ones you left out; mark those `unverified` rather than passing.

A slice with no rendered surface of its own still gets the sweep, through the page that consumes it. **Name that page.** "Backend only" is a claim about where the work surfaces, and the work surfaces somewhere.

Record the mechanism that set each width — the viewport control `help` documented, or the app loaded in a sized same-origin iframe on the control page. **The mechanism is part of the evidence.** "Works on mobile" with no width and no mechanism is not a QA result.

**Per slice and per width, capture one fact only the rendered page could produce** — a visible label, a computed style, an element count. Setting a width and moving on exercises nothing. Then read `mcp__tidewave__get_logs` with a `tail` and `level: "error"`; a screen that looks right over a 500 is not a pass. `mcp__tidewave__execute_sql_query` confirms an action wrote what it claimed.

## 4. Defect routing

**One defect, one GitHub issue. QA feeds the board; it returns no verdict and closes no lane.**

| Finding | Route |
| --- | --- |
| The app does the wrong thing | `gh issue create` with label `bug` → `diagnose-bug` |
| The app does what it was built to do, and that is the wrong thing to do | `capture-idea`, no issue |

**Never apply `afk`.** Only a completed diagnosis earns it and QA completes none; its absence puts a human on the route, which is correct here. Real labels: [triage-labels.md](../../../docs/agents/triage-labels.md). Tracker mechanics, epics, and sub-issues: [issue-tracker.md](../../../docs/agents/issue-tracker.md).

Each issue body carries the entry URL, the click path, the observed and expected behaviour, the widths where it reproduces, the widths where it does not, and any server error from `get_logs`. **A width where the defect disappears is the most valuable line in the body** — it hands `diagnose-bug` a bisect it would otherwise have to find.

## 5. Human stage

**Stop here and wait.** Hand Chris a testing list, then end the turn. Do not continue into `review-and-ship` and do not write a close that reads as though he already answered.

State four things: the slices and widths you exercised, the issues you opened, what you could not reach and why, and what needs his eyes. **Sound, real input devices, real network conditions, motion, focus order under a physical keyboard, and anything behind an email or payment step sit outside `browser_eval`.** Name them rather than letting silence imply coverage.

## Close

Name the slices with their widths, the issue URLs, every `unverified` slice or width, and the next skill — `review-and-ship` for the change, `diagnose-bug` for an issue Chris routes. Nothing auto-chains. Log `Decided: X by Chris` quoting his words, `Awaiting decision: <question>`, or `Decision points: none this round.`

**Learn hook — it produces an output either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill that changes no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
