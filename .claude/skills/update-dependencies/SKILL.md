---
name: update-dependencies
description: Use when dependencies are stale, a Dependabot PR needs reviewing or enriching, a named package needs upgrading, or our code must adapt to something a dependency deprecated or changed. Runs unattended weekly against the dependency PR.
---

# Update Dependencies

**Stance: autonomous inside the dependency lane** — `mix.exs` constraints, the lockfile, one branch, one pull request. Adding a package, crossing a major, and merging each need Chris.

Undefined terms — stance, the `Decided:` rule: [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` start at the repository root, not this file.**

**Headless.** Weekly cron, Tuesday 09:00 UTC, from `.github/workflows/dependency-update-report.yml`, which invokes this skill by path — renaming the skill means editing that workflow in the same change. Runners: Claude cloud or Codex cloud. 1 run/week, no fan-out. Output lands on the pull request this run opens; the Dependabot PR gets a comment pointing at it, then closes.

| Mode | Entry |
| --- | --- |
| **A — inspect** | "what's stale", or no approved target yet |
| **B — apply** | a named package, an approved set, or an existing Dependabot PR |

## Mode A — inspect

`mix deps.get`, then `mix hex.outdated` — a cold runner starts with no `deps/`. No `package.json` here, so Hex deps are the surface; Docker base images and GitHub Actions have their own Dependabot lanes. Report per package: current, latest, whether the constraint allows it, whether the jump crosses a major.

**Recommend, do not apply.** Group by risk so Chris can decide: minors with clean changelogs, majors with breaking changes. Patches auto-merge already — report them, never stage them.

## Mode B — apply

1. **Read the changelog between the two versions** — the range, not the latest release notes. Name every breaking change touching code we call. "No breaking changes" needs the changelog behind it. Vague changelog or code-level behavior at stake: inspect shipped source with `mix hex.package diff APP VERSION` (current-versus-target) or `mix hex.package diff PACKAGE VERSION1..VERSION2` (explicit range).
2. Narrow the `mix.exs` constraint deliberately. Update the lockfile. Prefer `mix igniter.upgrade <pkg>@<version>` where the package ships codemods; hand-edit only what it leaves.
3. Re-sync and read `deps/<package>/usage-rules.md` (`mix usage_rules.sync --yes`) before adapting our code. Recalled API knowledge is not evidence.
4. Repair compatibility **narrowly**. A bump is not licence to refactor; log anything else as a `find-violations` candidate. **Never add a package to repair a bump** — upstream dropping something we rely on means stop and hand back.
5. Verify with the canonical gate: `npm ci && npm audit` while this is a Node project; `mix ci` once the Elixir rewrite lands. Anything touching a data layer: read the generated migrations rather than assuming.

**Current reality:** `package.json` pins `x-ray` (last published 2019), `request-x-ray` (2016), `tg-yarl` (2016) and `rootpath` (2014), and `.github/dependabot.yml` ignores major bumps for `lowdb` and `x-ray`. These are not upgradeable in place — they are the reason for the Elixir proposal. Do not open bump PRs against them; route to the proposal instead.

## The PR report

Per bumped package: version to version and **one changelog or `mix hex.package diff` link**. No citation, no bump — a green suite is not a changelog. What could have broken us and why it did not. What you verified and how. Anything left unfixed.

"Updated deps, tests pass" is not a report — it hides the reasoning a reviewer needs.

**Never auto-merge.**

## Close

Artifact: the PR body on the branch this run opened, named with its URL. Next skill: `review-and-ship` for the human review pass, `handling-git` for push mechanics. Log `Decided: X by Chris` or `Decision points: none this round.`

**Learn hook — it outputs either way.** Name one thing that rubbed this run, or write "no friction". *Trivial* means a one-line edit to this skill changing no structure: make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not an escape from the other two.
