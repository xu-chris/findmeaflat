# Triage Labels

The labels that exist on `xu-chris/findmeaflat` and what each one authorises.

**Verify with `gh label list` before applying anything.** This file goes stale; the
repository does not.

## The automation label

**`afk` is the only label that grants authority.** It means: *Claude or another LLM may
pick this up and run it unattended.* Applying it **is** the approval — there is no
second, separate permission step.

**Its absence always means human in the loop.** Never read a missing label as consent.

There is deliberately no companion "an agent opened this" label. A label that records
authorship while granting nothing is noise: it appears next to `afk` often enough that
the two blur, and the moment they blur the authority grant stops being explicit. Git
authorship already records who opened what.

## Rules

- **Never apply `afk` to work you could not complete.** Only a completed diagnosis earns
  it. QA completes none, so **QA never applies it**.
- **Anything needing a product, legal, or architecture decision gets no `afk`**, and
  names the decision it needs instead. A licence-compatibility question is the worked
  example: mechanically it is just a dependency swap, but the choice is a judgement call,
  so `audit.yml` deliberately opens those issues without it.
- A label is not a substitute for a body. The body carries the evidence.

## Labels that exist today

Default GitHub set only:

`bug` · `documentation` · `duplicate` · `enhancement` · `good first issue` ·
`help wanted` · `invalid` · `question` · `wontfix`

## Labels that must be created

**`gh issue create --label` fails the entire call if any label is missing**, so the
workflows below break until these exist.

```bash
gh label create afk      --description "Claude or another LLM may run this unattended" --color 0E8A16
gh label create epic     --description "Parent issue for a vertical-slice fan-out"     --color 5319E7
gh label create security --description "Security vulnerability or hardening"           --color B60205
gh label create legal    --description "Licence, compliance, or data-protection decision" --color D4C5F9
gh label create dependencies --description "Dependency updates"                        --color 0366D6
```

Who needs them:

| Label | Needed by |
|---|---|
| `afk` | `ci.yml` claude-review job, `audit.yml` security issues, `fix-violation`, `fix-bug` |
| `security`, `bug`, `afk` | `audit.yml` → security issue |
| `legal`, `dependencies` | `audit.yml` → licence issue (no `afk`, by design) |
| `epic` | `plan-work` fan-out |

## Labels the Dependabot workflow expects but that do not exist

`.github/workflows/dependabot-auto-merge.yml` calls `gh pr edit --add-label` with:

`type:build` · `type:ci` · `breaking-change` · `dependencies:npm` ·
`dependencies:docker` · `dependencies:github-actions`

**None of these exist**, so those steps fail on every Dependabot PR. Either create them
or drop the labelling steps.
