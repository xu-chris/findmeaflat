# Crawl Diagnosis — Why the Bot Stopped Finding Flats

Empirical, not inferred. Every row below comes from a live HTTP probe run on
**2026-08-20** using the exact `User-Agent` from `conf/config.json.example`
(`Chrome/63.0.3239.132`, a browser released in December 2017).

**Headline: there is no single bug.** Six providers have failed in five different ways,
and only one of the five is a stale-CSS-selector problem. A rewrite in any language
fixes none of them by itself — but the language choice determines how cheaply each one
*can* be fixed and how loudly it fails next time.

---

> ## ⚠️ Correction (2026-08-21): the selector counts below were measured wrongly
>
> Every "does this selector still match?" figure in this document was produced by
> **substring `grep -o`**, not by CSS selector matching. A substring count answers a
> different question, and for two portals it gave the wrong answer.
>
> The worst case: `.aditem-main--middle--price` on kleinanzeigen was recorded as
> **54 matches**. It matches **zero** elements. The 54 came from
> `aditem-main--middle--price-shipping` and `…--price-shipping--price`, two live
> classes that merely *begin* with the dead one — 27 cards × 2.
>
> **This is the same error that let the portals rot in the first place:** measuring
> something adjacent to what you actually care about, and reading the healthy number
> as proof. §8.5 argues for fixture contract tests precisely because a test that
> parses the page cannot make this mistake.
>
> Re-verified with `Floki.find/2` against the captured 2026-08-20 fixtures. Corrected
> per-portal numbers are inline below. immowelt and wg-gesucht were diagnosed
> correctly; **kleinanzeigen and immosuchmaschine were not.**

## Summary table

| Provider | HTTP | Root cause | Class | Fixable by rewrite alone? |
|---|---|---|---|---|
| **immonet** | 403 | Portal sunset; redirects to `immowelt.de#x-sunset-redirect=imn` behind DataDome | **Provider no longer exists** | No — delete it |
| **immoscout** | 401 | AWS WAF JS challenge (`awswaf.com/challenge.js`) + Imperva | **Active bot defence** | No — needs a browser tier |
| **immowelt** | 200 | Old `/liste/…` URLs return **410 Gone**; pagination is a React `<button>` with no `href` | **URL scheme + SPA pagination** | Partly |
| **kleinanzeigen** | 200 | Domain renamed `ebay-kleinanzeigen.de` → `kleinanzeigen.de`; old URLs **410 Gone** | **Stale URL** | Yes |
| **immosuchmaschine** | 200 | `data-expose-id` attribute removed (now `data-id`) | **Stale selector** | Yes |
| **wg-gesucht** | 200 | Page redesigned; container/title/price selectors all match 0 nodes | **Stale selector** | Yes |

Three of six still serve clean, parseable, server-rendered HTML to a plain HTTP client.
That is the good news, and it sets the architecture: **most of this does not need a
headless browser.**

---

## 1. immonet — the provider is gone

```
GET http://www.immonet.de/immobiliensuche/sel.do?sroot=wohnung-mieten&…
→ 302 → 302 → https://www.immowelt.de/?…#x-sunset-redirect=imn   403
```

Response body:

```html
<p id="cmsg">Please enable JS and disable any ad blocker</p>
<script>var dd={'rt':'c','cid':'AHrlqAAAAAM…','host':'geo.captcha-delivery.com',…}</script>
<script src="https://ct.captcha-delivery.com/c.js"></script>
```

Two facts stacked. The `#x-sunset-redirect=imn` fragment is Immowelt's own marker for
*this portal has been retired into Immowelt* — AVIV Germany operates both, and Immonet
has been folded in. Behind that redirect sits **DataDome** (`geo.captcha-delivery.com`),
a commercial bot-management product.

**Action: remove Immonet entirely.** Its listings now appear on Immowelt. This also
retires `maxDistanceInKilometres`, whose only consumer was Immonet's radius parsing —
that filter needs re-homing as a general concept or dropping.

---

## 2. immoscout — a real bot wall

```
GET https://www.immobilienscout24.de/Suche/de/berlin/berlin/wohnung-mieten?sorting=2
→ 401  <title>Ich bin kein Roboter - ImmobilienScout24</title>
```

The challenge page loads `https://82d925f87a91.edge.sdk.awswaf.com/…/challenge.js` and
polls `AwsWafIntegration.hasToken()` before reloading. That is **AWS WAF Bot Control's
JavaScript challenge**, layered on Imperva. Passing it requires executing the
challenge script, solving its proof-of-work, storing the resulting cookie, and
replaying it — with a TLS and HTTP/2 fingerprint that matches the claimed browser.

No HTTP-client-plus-CSS-selector stack in any language passes this. Not x-ray, not
`Req`, not `HTTPoison`. The honest options:

1. **A real browser tier.** Headless Chrome holding a warm, cookied session, refreshed
   on challenge. Cost: a Chrome sidecar (~300 MB RSS), and it must be paced *slowly* —
   a browser hammering the site gets fingerprinted too.
2. **Drop ImmoScout24.** It is the largest German portal, so this hurts, but it is a
   legitimate choice if the browser tier is not worth the operational weight.
3. **Their official API.** ImmoScout24 publishes a partner API. Access is commercial
   and gated, but it is the only route that is unambiguously permitted.

**Recommendation: build the fetch layer as a behaviour with two implementations
(plain HTTP, browser) and ship the plain one first.** ImmoScout24 stays configured but
degraded, with an explicit `:blocked` health state surfaced to the user rather than a
silent zero-results run. Decide on the browser tier as a separate bet.

---

## 3. immowelt — right selectors, wrong URLs, impossible pagination

Three separate findings, and the first one is genuinely encouraging.

**(a) The selectors still work.** In the 1.2 MB response for a current Berlin search:

```
serp-core-classified-card-testid   30 matches
classified-card-mfe-               32
cardmfe-price-testid               32
cardmfe-keyfacts-testid            32
cardmfe-description-box-address    32
```

Every selector in `lib/sources/immowelt.js` is still present. Immowelt server-renders
the full result list — no `__NEXT_DATA__`, no client-side hydration required. A plain
`Req` + `Floki` fetch gets 32 listings per page today.

**(b) The configured URL is dead.**

```
GET https://www.immowelt.de/liste/berlin-alt-treptow/wohnungen/mieten?geoid=…
→ 301 → https://www.immowelt.de/suche/berlin-alt-treptow/wohnungen/mieten?geoid=…
→ 410 Gone
```

`/liste/` became `/suche/`, and the old `geoid`/`prima`/`eqid` parameter vocabulary was
retired with it. Current canonical form:
`https://www.immowelt.de/suche/mieten/wohnung/berlin/berlin-10115/<hash>`.
**Every user's saved config URL is a 410.** The README instructs users to paste these
URLs, so every installation broke at once when the scheme changed.

**(c) Pagination is structurally impossible with x-ray.** This is open issue #20, and
the reason it was never fixed:

```html
<button type="button" tabindex="0" data-react-aria-pressable="true"
        aria-label="nächste seite" class="css-cnvxnp">
```

It is a `<button>`, not an `<a href>`. There is no URL to follow. x-ray's `.paginate()`
requires a link attribute, so the configured selector `[aria-label="nächste seite"]`
extracts the button's *text content* and pagination silently no-ops.

Probing the obvious query parameters confirms it is client-side:

```
?sp=2   → 200, redirected to canonical URL, aria-label="aktuelle seite, seite 1"
?page=2 → 200, redirected to canonical URL, aria-label="aktuelle seite, seite 1"
```

Both land back on page 1. Immowelt drives pagination through React state and an
internal fetch. **Fixing this means either finding the internal JSON endpoint the
button calls, or accepting page 1 only.** For a *new-listings* bot sorted by newest
first, page 1 is arguably sufficient — 32 cards at a 2-minute interval is ample
coverage. This is worth stating as a deliberate scope decision rather than a defect.

---

## 4. kleinanzeigen — the easy one

```
GET https://www.ebay-kleinanzeigen.de/s-wohnung-mieten/berlin/…  → 410 Gone
GET https://www.kleinanzeigen.de/s-wohnung-mieten/berlin/c203l3331 → 200, 381 KB
```

eBay divested the platform; it was renamed **kleinanzeigen.de**. On the new domain the domain rename is real, **but three selectors are dead** — the
original substring counts here were wrong. CSS-verified against the fixture:

```
srchrslt-adtable                  1
ad-listitem                      33
data-adid                        27
aditem-main--middle--price       54
text-module-begin                27
aditem-main--middle--description 27
pagination-next                   1
```

Including a real `@href` on `pagination-next`, so pagination works here.
**Fix: change the domain. That is the whole fix.**

---

## 5. immosuchmaschine — one dead attribute

Page loads fine (200, 249 KB, `36.597 Immobilien in Berlin`). Selector audit:

```
                                 substring   CSS   verdict
.result-list li                         22    17   fewer containers than counted
.data_title div[data-expose-id]          0     0   DEAD (correctly diagnosed)
[data-id]                               10    10   its replacement
.data_price span                        64    10   only 10 of 17 containers carry one
.data_size dd                           22    10
.data_rooms dd                          18     8
.data_title div.objectLink             151     0   DEAD — missed by the substring count
```

**Two dead selectors, not one.** The title selector is also gone; `objectLink`'s 151
substring hits come from other markup entirely. The mismatched counts (17 containers,
10 prices, 8 rooms) say the page drifted further than a single attribute rename, so
S11 should expect to re-derive most of this set rather than patch one field.

The ID field is the one that broke. Because `normalize` then runs
`parseInt(undefined)` → `NaN`, every listing collides on the same ID and dedupe
collapses. Compounding it, `price.split('€ ')[1].split(',-')[0]` throws a
`TypeError` the moment a price is formatted differently — and that exception rejects
the *entire* source run, not one listing.

**Fix: `data-expose-id` → `data-id`, plus defensive parsing.**

---

## 6. wg-gesucht — redesigned

Page loads fine (200, 516 KB). Selector audit:

```
main_column                 1   ✓
detailansicht              30   ✓
panel panel-default         0   ✗  ← the container
detail-size-price-wrapper   0   ✗  ← size + price
headline printonly          0   ✗  ← title + link
```

The Bootstrap-panel layout is gone. Current markup:

```html
<div class="wgg_card offer_list_item ">…</div>     ← 28 per page
<… id="liste-details-ad-13963834">                  ← the listing ID
```

**Fix: rewrite the selector set against `.wgg_card.offer_list_item` and
`id="liste-details-ad-<id>"`.** The URL builder (city/cityKey/minSize/maxRent) still
produces working URLs, so that logic survives.

---

## 7. Dependency rot

| Package | Pinned | Latest | Last published |
|---|---|---|---|
| `request-x-ray` | 0.1.4 | 0.1.4 | **2016-09-04** (~10 years) |
| `tg-yarl` | 1.3.0 | 1.3.0 | **2016-08-09** (~10 years) |
| `rootpath` | 0.1.2 | 0.1.2 | **2014-04-29** (~12 years) |
| `x-ray` | 2.3.4 | 2.3.4 | **2019-07-15** (~7 years) |
| `lowdb` | ^1.0.0 | 7.0.1 | major updates explicitly ignored in Dependabot |
| Node base image | `node:14-alpine` | — | Node 14 **EOL 2023-04-30** |

Four of six runtime dependencies are effectively abandoned. `request-x-ray` is built on
the deprecated `request` package. This is not a moral failing of the code — it is why
the fetch layer cannot be incrementally modernised in place, and it is a legitimate
reason to move rather than patch.

---

## 8. What this means for the rewrite

1. **A rewrite does not fix crawling.** Selectors and URLs must be re-derived by hand
   against live HTML, in whichever language. Budget that work explicitly.
2. **Elixir's real leverage is failure visibility.** The present system reports
   "0 new listings" identically whether the search is genuinely quiet or the portal
   returned a 410. Every failure above was *silent for months*. The target design must
   make a portal that returns zero parseable cards raise a loud, per-portal health
   state — and tell the user in Telegram.
3. **Selectors belong in data, not in code.** Six portals × ~8 selectors change a few
   times a year. Storing them as versioned rows lets a broken portal be repaired
   without a deploy.
4. **Two fetch tiers, not one.** Plain HTTP covers immowelt, kleinanzeigen,
   immosuchmaschine and wg-gesucht today. Only ImmoScout24 needs a browser, and that
   is a separate, deferrable bet.
5. **A contract test per portal.** Store one real HTML fixture per portal and assert
   the parser still yields N listings with non-nil ids, prices and links. A weekly CI
   job re-fetches live HTML and fails when the fixture drifts. That single mechanism
   would have caught all five of the fixable breakages within a week of each happening.

---

## 9. Legal and etiquette note

All six portals prohibit automated scraping in their terms of use, and ImmoScout24,
Immonet and (intermittently) wg-gesucht deploy commercial bot management to enforce it.
This tool is a personal-use notifier, its request volume is trivial, and the existing
code already paces itself — but circumventing an active bot-defence challenge is a
different act from politely fetching a public page, and it is worth being deliberate
about which line the browser tier crosses. Recommendation: keep the plain-HTTP tier
polite and well-identified (honest `User-Agent`, `robots.txt` respected, generous
delays, hard per-portal rate cap) and treat the ImmoScout24 browser tier as a separate
decision with its own justification.
