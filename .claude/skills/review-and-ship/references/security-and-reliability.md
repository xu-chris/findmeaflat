# Security and Reliability Review Prompts

Load only when the changed surface crosses a trust, data, external-effect, or runtime boundary. Every finding needs changed source evidence, a plausible trigger, impact, and current project or first-party authority. A checklist match alone is not a finding.

## Trust and data boundaries

- Authentication, authorization, ownership, tenancy, and object-reference checks fire at every newly reachable read or write.
- Client-supplied IDs, roles, flags, URLs, paths, and serialized values carry no authority.
- SQL, shell, template, HTML, URL-fetch, and filesystem construction blocks injection, XSS, SSRF, and traversal at the owning boundary.
- Secrets, tokens, credentials, and personal data stay out of code, client payloads, logs, exceptions, traces, fixtures, and version control.
- Cryptographic use validates algorithm, key material, expiry, issuer, audience, randomness, and authenticated encryption through established libraries.

## Reliability and effects

- External calls bound timeout, retry, idempotency, rate, and failure behavior to their effect.
- Loops, recursion, buffers, queries, pagination, concurrency, and background work stay bounded under realistic input.
- Writes preserve invariants across partial failure, duplicate delivery, check-then-act races, rollback, and retry.
- Deployment, migration, configuration, and dependency changes carry explicit compatibility and recovery evidence.
- Performance claims are measured at the changed hot path. Never demand a cache, index, batch, process, or concurrency mechanism without evidence.

## Framework evidence

For non-obvious Ash, Phoenix, LiveView, OTP, Ecto, or dependency behavior, put version-matched usage rules or first-party source in the packet. Unsupported framework claims are `unverified`.
