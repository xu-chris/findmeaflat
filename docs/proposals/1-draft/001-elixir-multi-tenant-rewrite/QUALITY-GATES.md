# Quality and Security Gates

Every package you named, verified against the Hex API on **2026-08-20**. Versions,
licences, maintenance status, what each actually catches, where they overlap, and the
four I would change.

The set shares a theme worth making explicit: **most of it exists to catch problems that
AI-assisted code introduces.** Since this rewrite will largely be built by an agent,
that is not incidental tooling — it is the control loop. The Node app it replaces has no
test suite and no static analysis whatsoever, so anything here is a strict improvement.
The risk is the opposite one: **too many overlapping linters produce noise, noise gets
suppressed wholesale, and a suppressed gate is no gate.** §7 deals with that.

---

## 1. Verified inventory

### Security

| Package | Your pin | Latest | Updated | Licence | Note |
|---|---|---|---|---|---|
| `mix_audit` | `~> 2.1` | 2.1.5 | 2025-06-09 | BSD-3 | ✅ 11.1M downloads |
| `sobelow` | `~> 0.13` | 0.15.0 | 2026-08-05 | Apache-2.0 | ✅ 41.5M downloads |
| `exploit_guard` | `~> 1.0.0` | 1.0.0 | **2023-06-07** | Apache-2.0 | ⚠️ **see §3** |

### Migration safety

| Package | Your pin | Latest | Updated | Licence | Note |
|---|---|---|---|---|---|
| `excellent_migrations` | `~> 0.1` | 0.1.10 | 2026-03-06 | MIT | ✅ 4.2M downloads — **strongest addition in the list** |

### Credo plugins and semantic linters

| Package | Your pin | Latest | Updated | Licence | Checks |
|---|---|---|---|---|---|
| `ex_slop` | — | 0.4.4 | 2026-07-25 | MIT | 40 (31 default) |
| `jump_credo_checks` | — | 0.4.0 | 2026-06-12 | MIT | 22 |
| `oeditus_credo` | `~> 0.8.1` | **0.11.1** | 2026-08-19 | MIT | **58** — incl. CWE Top 25 |
| `credence` | `~> 0.8.0` | 0.8.1 | 2026-07-02 | MIT | performance + idiom |
| `llamex` | — | unreleased | 2026-08-16 | **none** | 6, Ash-aware |

### Formatting, docs, duplication, dev loop

| Package | Your pin | Latest | Updated | Licence | Note |
|---|---|---|---|---|---|
| `quokka` | `~> 2.7` | 2.13.1 | 2026-05-19 | Apache-2.0 | **Styler fork — see §4** |
| `ex_dna` | `~> 1.5` | 1.5.4 | 2026-07-17 | MIT | duplication detector |
| `doctor` | `~> 0.21` | 0.23.0 | 2026-05-16 | MIT | doc coverage |
| `excoveralls` | `~> 0.18` | 0.18.5 | 2025-01-26 | MIT | ✅ your "never a gate" note is right |
| `mix_test_watch` | `~> 1.0` | 1.4.0 | 2025-10-21 | MIT | ✅ |
| `git_hooks` | `~> 0.9.0` | 0.9.0 | 2026-07-10 | MIT | ⚠️ conflicts — §5 |
| `tidewave` | `~> 0.8.0` | **0.9.0** | 2026-08-20 | Apache-2.0 | pin excludes current — §6 |

---

## 2. The four security tools, and what each buys here

**`sobelow`** — Phoenix security static analysis. This app's attack surface is larger
than the Node version's, in three specific ways:

- **The Telegram webhook is a public, unauthenticated POST endpoint.** Telegram's
  documented protection is a secret path segment plus the
  `X-Telegram-Bot-Api-Secret-Token` header; both must be verified.
- **Scraped HTML flows into rendered output.** Listing titles are attacker-influenced
  text from six third-party sites, reaching Telegram messages and later a LiveView UI.
- **Magic-link auth** once the web surface exists.

```bash
mix sobelow --exit high
```

Replaces what CodeQL does for JavaScript in `.github/workflows/security.yml` today.

**`mix_audit`** — known CVEs in dependencies. Direct replacement for `npm audit`.
Pair with `mix hex.audit` (built in) for retired packages.

**`excellent_migrations`** — and this one deserves emphasis, because it is the highest
value-per-line package in your whole list *for this specific project*.

`TARGET-ARCHITECTURE.md` and `STACK.md` put schema evolution in the hands of
`mix ash.codegen`, which **generates migrations you did not write**. Ash is good at
this, but generated DDL still has to be read before it runs against a database holding
a year of listings. `excellent_migrations` catches exactly the class of thing that is
easy to miss in a generated diff: adding a column with a default to a large table,
adding an index without `concurrently`, backfilling in the same transaction as a schema
change, `NOT NULL` on an existing column, renaming or dropping a column still read by
running code.

`STACK.md` §5 already says "read the generated SQL before running it." This makes that
mechanical instead of aspirational:

```bash
mix excellent_migrations.check_safety
```

---

## 3. `exploit_guard` — the one I would drop

It is the only **runtime** dependency in the list. Everything else is
`only: [:dev, :test], runtime: false` and never reaches production; this ships in the
release and executes in the request path.

Verified facts:

- **A single release, 1.0.0, published 2023-06-07.** Nothing in three years.
- 34,806 total downloads — three orders of magnitude below `sobelow`'s 41.5M.
- From `paraxialio` (Paraxial.io, the Elixir security vendor), Apache-2.0.
- It is **RASP** — Runtime Application Self-Protection: in-process hooks that inspect
  and block traffic at runtime.

Three reasons to leave it out of this project:

1. **Unmaintained code in the production request path is a net negative for security.**
   A RASP layer sits where it can see everything; a version frozen since 2023 that will
   not receive a fix is a worse bet than not having it.
2. **It does not match the threat model.** RASP defends a web application against
   hostile inbound traffic. This app's inbound surface is one Telegram webhook with a
   shared-secret header. Its actual risk is *outbound* — six hostile-ish third-party
   sites feeding untrusted HTML into a parser. RASP does not address that; Sobelow's XSS
   checks and disciplined escaping do.
3. **The one real inbound risk is better solved directly** — verify the Telegram secret
   token, rate-limit the endpoint with `PlugAttack` or `Hammer`, and reject oversized
   bodies. Twenty lines of plug, no unmaintained runtime dependency.

**Recommendation: drop it.** If runtime protection is wanted later, Paraxial.io's hosted
product is the maintained path, and it is a decision to make deliberately rather than
inherit from a 2023 package.

---

## 4. `quokka` vs `styler` — pick one, and it should be Quokka

Quokka's own README: *"Quokka is a fork of Styler that checks the Credo config to
determine which rules to rewrite."* **Both are formatter plugins that rewrite the same
AST. Running both is a conflict, not a stack.** An earlier draft of this document listed
Styler; Quokka supersedes it and Styler should not appear in `mix.exs`.

Quokka is the better fit here precisely because it reads `.credo.exs`: with five Credo
plugins configured, having the auto-formatter derive its behaviour from the same config
avoids the formatter and the linter disagreeing.

**Heed its warning.** The README states plainly: *"Quokka can change the behavior of
your program! In some cases, this can introduce bugs."* On a greenfield codebase with
no legacy this is low-risk, but the operational rule matters: **run Quokka's first
full-codebase pass as its own commit, with nothing else in it**, so a behaviour change
is bisectable. Never let it land mixed into a feature commit.

Your pin `~> 2.7` resolves to 2.13.1 — fine.

---

## 5. `git_hooks` — conflicts with what is already here

This repo already ships `.agents/hooks/install-git-hooks.sh`, alongside
`protect-secrets.sh`, `worktree-init.sh` and `elixir-worktree-setup.sh`. That harness is
client-neutral by design (`.agents/README.md`), and `protect-secrets.sh` is already
active — it blocked reading `.env.sample` during this very research.

`git_hooks` (the Elixir package) installs and manages hooks from `config.exs`. Two hook
installers writing `.git/hooks/pre-commit` will fight, and the last one to run wins
silently.

**Decide, do not stack.** Either:

- **Keep the shell harness** (it already works, is client-neutral, and predates this
  proposal) and have its `pre-commit` call `mix precommit`; or
- **Adopt `git_hooks`** and fold the shell scripts into its config — but then
  `protect-secrets.sh` must be ported, and losing it would be a real regression.

Recommendation: **keep the shell harness, skip `git_hooks`.** Phoenix 1.8 generates a
`mix precommit` alias; one line in the existing hook calls it. Fewer moving parts, and
the secret protection stays where it is.

---

## 6. Version pins to adjust

| Package | Your pin | Resolves to | Issue |
|---|---|---|---|
| `oeditus_credo` | `~> 0.8.1` | 0.8.x only | **Excludes 0.11.1** (2026-08-19). `~> 0.8.1` means `>= 0.8.1 and < 0.9.0`. Use `~> 0.11` |
| `tidewave` | `~> 0.8.0` | 0.8.x only | **Excludes 0.9.0** (2026-08-20). Use `~> 0.9` |
| `sobelow` | `~> 0.13` | 0.15.0 ✅ | Fine — `~> 0.13` allows `< 1.0.0` |
| `doctor` | `~> 0.21` | 0.23.0 ✅ | Fine |
| `quokka` | `~> 2.7` | 2.13.1 ✅ | Fine |

The `~> 0.8.1` vs `~> 0.8` distinction bites twice here: with three version components
the constraint locks the patch series; with two it allows minor bumps.

Also: `tidewave` is `only: :dev` in your list, which is right — it is a dev-time MCP
server, not something to ship.

---

## 7. The composition problem — the part that decides whether any of this works

Counting third-party checks now configured on top of Credo's own ~100:

| Source | Checks |
|---|---|
| `oeditus_credo` | 58 |
| `ex_slop` | 40 (31 on by default) |
| `jump_credo_checks` | 22 |
| `llamex` | 6 |
| `credence` | semantic analysis, unenumerated |
| **Total** | **≈126+ third-party checks, five plugins** |

These overlap substantially. Known collisions:

- `credence` (performance + non-idiomatic via AST) vs `ex_slop`'s ~25 `Refactor.*` checks
  — **large overlap**, same target from two directions.
- `oeditus_credo`'s CWE-security checks vs `sobelow` — both cover injection and XSS.
- `llamex.NoDBWorkInMemory` vs `ex_slop.Warning.RepoAllThenFilter` — same defect.
- Quokka auto-rewrites style findings that three of the plugins also report.

Turning all of this on at once on day one produces hundreds of findings on a fresh
Phoenix skeleton, the team disables checks in bulk to get to green, and the gates that
mattered die alongside the noise. **Sequence the adoption:**

| Step | Add | Gate? | Rationale |
|---|---|---|---|
| 1 | Credo default + Quokka + `mix format` | blocking | Establish a formatted, green baseline |
| 2 | `sobelow`, `mix_audit`, `excellent_migrations` | **blocking** | Security and migration safety, near-zero false positives, highest value |
| 3 | `ex_slop` | blocking | Verify the plugin is actually live — see §8 |
| 4 | `jump_credo_checks` | blocking | Disable `UseObanProWorker` immediately (§9) |
| 5 | `oeditus_credo` | advisory → blocking | 58 checks; triage before gating. Drop any duplicating sobelow |
| 6 | `credence` | advisory | Judge purely on what it finds that `ex_slop` did not. Drop if the answer is "nothing" |
| 7 | `llamex` | advisory | Promote `NoAuthorizeBypass` + `NoAdHocAshQueries` to blocking once clean (§10) |
| 8 | `ex_dna`, `doctor` | advisory, never blocking | Duplication and doc coverage are signals, not standards |

**Rule: every disabled check carries a one-line comment saying why.** Otherwise
`.credo.exs` becomes a list of things somebody once found annoying, and nobody can tell
a deliberate exemption from an unexamined one.

**Rule: `excoveralls` stays out of the gate** — your own note says this, and it is
correct. Coverage as a gate produces tests written to touch lines. `jump_credo_checks`'
`VacuousTest` is the better instrument, because it attacks the thing coverage
percentages hide.

---

## 8. `ex_slop` — 40 checks against generated code

Maps directly onto failure modes this architecture must avoid:

| Check family | Why it matters here |
|---|---|
| `Warning.BlanketRescue`, `RescueWithoutReraise` | The Node code swallows errors and marks listings seen. The Elixir version returns `{:error, reason}`; blanket rescues would reintroduce the exact bug |
| `Warning.RepoAllThenFilter`, `QueryInEnumMap` | Matching must happen **in the database** (`TARGET-ARCHITECTURE.md` §5). These catch the load-then-filter and N+1 versions an agent reaches for |
| `Warning.GenserverAsKvStore` | The design has exactly one legitimate GenServer family (`PortalGate`). Flags invented ones |
| `Readability.NarratorDoc`, `ObviousComment`, `StepComment` | Generated code narrates itself; `.claude/skills/build/references/backend/architecture.md` asks for matching surrounding comment density |
| `Refactor.*` (~25) | Anti-idiomatic `Enum` chains, `sort \|> at`, `reduce` used as `map`, identity passthrough |

**Silent-failure trap, documented by the project.** `plugins: [{ExSlop, []}]` only works
if `.credo.exs` does **not** declare an explicit `checks.enabled` list. If you have ever
run `mix credo.gen.config`, you have one, Credo treats it as authoritative, and **the
plugin contributes nothing.** Fix:

```elixir
checks: %{
  enabled: [ ...existing... ] ++ Enum.map(ExSlop.recommended_checks(), &{&1, []})
}
```

ExSlop prints a warning, but a warning inside a wall of Credo output is easy to miss.
**Verify by writing a deliberate blanket `rescue` and confirming it gets flagged.** A
gate nobody has watched fail is not a gate — which is the same lesson as
`CRAWL-DIAGNOSIS.md`.

---

## 9. `jump_credo_checks` — correctness and test quality

Published on Hex as **`jump_credo_checks`**; the repo is `Jump-App/credo_checks`, so
the package name differs from the repo name.

**Test-quality checks, aimed squarely at generated tests:**

- `VacuousTest` — tests that call no application code. Its README names this explicitly
  as "useful to detect poor-quality tests generated by LLMs"
- `TestHasNoAssertions`, `WeakAssertion`, `ConditionalAssertion` (`assert a or b`)
- `TooManyAssertions` (default 20)
- `AssertReceiveTimeout` — timeouts that pass locally and flake on CI

This matters more here than in a typical project. `STACK.md` §6 makes **portal fixture
tests the primary defence against silent breakage**. A suite of vacuous tests would show
green CI while the crawler is dead — exactly the failure this whole rewrite exists to
prevent.

**Correctness:** `AvoidFunctionLevelElse` (botched refactors that crash at runtime),
`SafeBinaryToTerm` (atom-table exhaustion from attacker input), `UndeclaredExternalResource`
(compile-time `File.read!` without `@external_resource` — relevant, since seeded selector
sets and digitised Mietspiegel CSVs get read from `priv/`), `TopLevelAliasImportRequire`.

**LiveView (Phase 2+):** `LiveViewFormCanBeRehydrated`, `UnusedLiveViewAssign`,
`AssertElementSelectorCanNeverFail`, `AvoidSocketAssignsInTest`.

**Two to configure, not accept:**

- **`UseObanProWorker` — disable.** It enforces `use Oban.Pro.Worker`. This project uses
  **Oban OSS**; see `TARGET-ARCHITECTURE.md` §5 for why `PortalGate` exists as a process
  instead of Pro's rate limiting. Left on, it fails every worker in the app.
- **`PreferTextColumns`** — good policy, but migrations here come from `mix ash.codegen`
  and are not hand-written. Check it against real generated output before enabling;
  disable rather than fight the generator.

---

## 10. `llamex` — Ash-aware, three caveats

Six checks. Two are directly on-target for this architecture:

| Check | Relevance |
|---|---|
| **`NoAuthorizeBypass`** | Ash `authorize?: false` slipped into a code path. In a **multi-tenant** app where policies are the only thing keeping subscribers out of each other's searches, this is the single most valuable check in this document |
| **`NoAdHocAshQueries`** | Queries bypassing code interfaces — the thing that erodes an Ash domain into scattered `Ash.read!` calls |
| `NoDBWorkInMemory` | Load-then-filter in Elixir instead of Postgres. Overlaps `ex_slop.RepoAllThenFilter` |
| `NoSelfInLiveViews`, `ConsistentInterfaces`, `NoOneLiners` | Phase 2+ / style |

**Caveats, all verified, none disqualifying:**

1. **Not on Hex.** The README suggests `path: "../llamex"`, which needs a second
   checkout in CI. Prefer `{:llamex, github: "dmitriid/llamex", only: [:dev, :test],
   runtime: false}` — pins by SHA in `mix.lock`, no extra CI wiring.
2. **No licence.** Verified: no licence file in the repository, GitHub API reports
   `license: null`. Default copyright means *all rights reserved* — no grant to use or
   distribute. For a dev-only dependency that is never distributed the practical risk is
   low, but `PRODUCT-VISION.md` §5 raises a possible commercial product and this repo is
   MIT. **Open an issue asking the author to add a licence.** Cheap to ask, cheap to
   drop if declined.
3. **Self-described as vibe-coded.** Its README: an AI agent wrote most of it, "review
   each finding before you change code." Three stars, active as of 2026-08-16. That
   argues for advisory-only, not for skipping it — `NoAuthorizeBypass` alone justifies
   the install.

---

## 11. Resulting `mix.exs` dev/test block

```elixir
# Security
{:sobelow, "~> 0.15", only: [:dev, :test], runtime: false},
{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
# exploit_guard deliberately omitted — single 2023 release, runtime dep,
# wrong threat model. See QUALITY-GATES.md §3.

# Migration safety — Ash generates the migrations, so this is not optional
{:excellent_migrations, "~> 0.1", only: [:dev, :test], runtime: false},

# Style — Quokka only. NOT Styler: Quokka is a fork of it (§4)
{:quokka, "~> 2.13", only: [:dev, :test], runtime: false},

# Credo + plugins, adopted in the order given in §7
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
{:jump_credo_checks, "~> 0.4", only: [:dev, :test], runtime: false},
{:oeditus_credo, "~> 0.11", only: [:dev, :test], runtime: false},
{:credence, "~> 0.8", only: [:dev, :test], runtime: false},
{:llamex, github: "dmitriid/llamex", only: [:dev, :test], runtime: false},

# Analysis
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
{:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
{:doctor, "~> 0.23", only: [:dev], runtime: false},

# Dev loop
{:mix_test_watch, "~> 1.4", only: [:dev, :test], runtime: false},
{:tidewave, "~> 0.9", only: :dev},

# Coverage — local, on demand, never a gate
{:excoveralls, "~> 0.18", only: :test, runtime: false}

# git_hooks omitted — .agents/hooks/install-git-hooks.sh already owns this (§5)
```

---

## 12. CI

Replaces the npm-audit and CodeQL jobs in `.github/workflows/security.yml`. Trivy
(image scanning) and TruffleHog (secret scanning) are language-agnostic and stay.

```yaml
- run: mix deps.get
- run: mix compile --warnings-as-errors
- run: mix format --check-formatted
- run: mix credo --strict                        # + ex_slop, jump, oeditus
- run: mix sobelow --exit high
- run: mix deps.audit
- run: mix hex.audit
- run: mix excellent_migrations.check_safety
- run: mix test
- run: mix dialyzer                              # PLT cached

# advisory, continue-on-error: true
- run: mix credo --strict --checks Llamex
- run: mix ex_dna
- run: mix doctor
```

Two project-specific jobs matter more than any of the above, from `CRAWL-DIAGNOSIS.md` §8:

- **Portal fixture tests** inside `mix test` — stored HTML per portal, asserting ≥N
  listings parse with non-nil id/title/url.
- **A weekly live-drift job**, separate from PR CI, that re-fetches each portal and fails
  when live HTML stops matching its `SelectorSet`.

That second job would have caught all five fixable portal breakages within a week of
each occurring. **It is the single highest-value item in this document, and no amount of
static analysis substitutes for it.** Worth stating plainly, because 126 lint checks are
easy to mistake for the thing that keeps this app working, and they are not.
