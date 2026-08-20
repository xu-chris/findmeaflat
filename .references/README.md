# References — the original Node.js crawler

**Read-only history. Not maintained, not run, not gated by CI.**

This is the Node.js implementation of FindMeAFlat, moved here when the Elixir
rewrite took the repository root. It is kept because its selectors, normalisation
rules and filter semantics are the specification the Elixir port works from — not
because anyone intends to run it again.

## What is here

```
index.js                 boot, source loading, setInterval scheduler
lib/flatfinder.js        the per-source pipeline
lib/scraper.js           shared x-ray instance (HTTP + CSS extraction)
lib/store.js             lowdb JSON file of seen listing IDs
lib/notify.js            single Telegram bot, single hard-coded chat ID
lib/sources/*.js         six provider definitions — the useful part
conf/config.json.example the full configuration schema
Dockerfile, Makefile     how it was built and run
```

## Why it is not runnable

Five of six portals no longer crawl, in five different ways: Immonet was sunset
into Immowelt, ImmoScout24 returns 401 behind an AWS WAF challenge, Immowelt and
Kleinanzeigen URLs return 410 after scheme and domain changes, and wg-gesucht was
redesigned. Four of six runtime dependencies were last published between 2014 and
2019, and the base image (`node:14-alpine`) has been end-of-life since 2023-04-30.

Per-portal evidence, with the probe that produced it:
[`docs/proposals/1-draft/001-elixir-multi-tenant-rewrite/CRAWL-DIAGNOSIS.md`](../docs/proposals/1-draft/001-elixir-multi-tenant-rewrite/CRAWL-DIAGNOSIS.md)

The behavioural spec derived from this code — every selector, every normalisation
quirk, every latent bug — is in
[`CURRENT-SYSTEM.md`](../docs/proposals/1-draft/001-elixir-multi-tenant-rewrite/CURRENT-SYSTEM.md).
**Read that before reading the code**; it already records what the code does and
where it is wrong.

## Licensing

Not covered by the repository's AGPL-3.0 grant, which applies to the Elixir
implementation only. No LICENSE has ever existed for this code. See
[`NOTICE`](../NOTICE).

## What CI does with it

Nothing, deliberately. The Node lane in `ci.yml` and the npm and docker
ecosystems in `dependabot.yml` were retired when this moved: a red build on
archived code trains everyone to ignore CI, and dependency PRs against it would
be noise nobody should merge.

`conf/config.json` and `db/listing.json` remain gitignored — the former held a
Telegram bot token.
