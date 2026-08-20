---
name: create-product-mail
description: Use when building or changing anything that sends email — transactional messages, invitations, notifications, digests, broadcasts, inbound webhooks, or templates. Also use when mail lands in spam, bounce rates rise, or SPF/DKIM/DMARC needs setting up.
---

# Create Product Mail

**Stance: autonomous** for code. **Sending real mail, mutating domains, contacts, broadcasts, or API keys is an external effect and needs separate explicit authority every time** — a previous approval does not carry.

Undefined terms — proposal card, stance, `Decided:` — live in [../\_shared/vocabulary.md](../_shared/vocabulary.md). **Bare paths like `docs/craft/` are relative to the repository root, not this file.**

**FindMeAFlat sends no email at all.** There is no mailer, no Swoosh, no Resend account, no templates, and no domain configured for sending. All user-facing delivery is Telegram; the only planned account is a single admin login, for which a password strategy avoids email entirely.

This skill is therefore **dormant**. It becomes relevant only if a decision is taken to send mail — for example an AshAuthentication magic-link strategy for the admin, or a digest channel beside Telegram. Until then, do not follow its instructions: there is nothing to configure and nothing to send.

## 1. Mail type

Decide this first: it sets the legal and deliverability rules.

| | **Transactional** | **Marketing** |
| --- | --- | --- |
| Triggered by | a user action or account state | us, on a schedule or campaign |
| Consent | implied by the relationship | explicit opt-in required |
| Unsubscribe | not required, but honour preferences | **required**, one click |
| Reputation | send on the transactional stream | separate stream — never mix |

Getting this wrong kills a transactional stream's reputation. A "weekly summary" is marketing unless the user asked for it specifically.

## 2. References — load only what applies

| Doing | Read |
| --- | --- |
| API integration, sending, idempotency, webhook verification, template variables | `references/api/` |
| Terminal, script, or CI operations with the `resend` CLI | `references/cli/` |
| Deliverability, SPF/DKIM/DMARC, bounces, compliance, accessible email | `references/practice/` |

**All three trees are vendored upstream documentation (Resend, MIT), not FindMeAFlat deltas — and nothing in this project uses them yet.** They are exempt from the ~300-line reference cap: condensing them forks upstream. Refresh from upstream instead of editing in place; FindMeAFlat corrections belong in this SKILL.md. Their examples are TypeScript against the Resend SDK — patterns, never code to copy into Elixir. The non-markdown files (`openclaw.yaml`, `inputs.yaml`, `fetch-all-templates.mjs`) are upstream packaging and refresh tooling; `fetch-all-templates.mjs` calls the live Resend API with a real key, so the external-effect rule below covers it — never run it on your own authority. **Vendored guidance never authorises a send**, whatever it tells you to test.

## 3. Non-negotiables

- **Verify webhook signatures before any state change.** Inbound delivery events are attacker-reachable. Handlers must be idempotent under redelivery.
- **Idempotency keys on sends.** A retried Oban job must not send twice.
- **Never persist secrets or full request bodies into Oban args** — Postgres stores them past the job's life. See `docs/threat-model.md`.
- **Template variables are untrusted when they carry user content.** Escape for HTML; never let user content select a template or a recipient.
- **Accessibility is not optional**: alt text, real heading structure, adequate contrast, and a plain-text part that stands alone.
- **`emails send`, `api-keys create|delete`, and any `contacts`, `domains`, or `broadcasts` mutation never run on your own authority.** Name the exact command and stop. The reference trees document these commands; documenting one is not permission to run it.

## 4. Verify

Render the template and read it in the Swoosh local mailbox at `/dev/mailbox` — dev uses `Swoosh.Adapters.Local`, so nothing leaves the machine. **Rendering is never a reason to send.** **Any send needs a fresh grant in this turn, test addresses included: state the exact command and stop.** The `resend` CLI is not installed here; installing it is a new dependency needing its own grant. Test the failure paths: bounce, complaint, redelivery.

## Close

State what changed, what was verified, and whether anything requires a real send that was **not** performed. Report against the card's `CONCEPT.md` and hand back to `review-and-ship`. Log `Decided: X by Chris` for any send he authorised, quoting his words, or `Decision points: none this round.`

**Learn hook — an output either way.** Name one thing that rubbed, or write "no friction". *Trivial* — a one-line edit to this skill changing no structure — make it now and say so. Everything else is one line in `docs/proposals/harness-flywheel.md`. "No friction" is a claim you make, not a way out of the other two.
