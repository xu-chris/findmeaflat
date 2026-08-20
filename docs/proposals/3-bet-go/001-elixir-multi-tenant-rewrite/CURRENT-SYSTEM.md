# Current System — Reverse-Engineered Specification

Complete behavioural spec of the Node.js application as it stands at commit `6bc4e8e`
(2025-06-08). This is the contract the Elixir version has to honour or deliberately
break. Nothing here is aspirational — every statement is read out of the source.

**Language note:** the app is plain CommonJS JavaScript, not TypeScript. There is no
build step, no type checking, and no test suite.

---

## 1. Runtime shape

```
index.js                 boot, source loading, setInterval scheduler, signal handling
lib/flatfinder.js        the per-source pipeline (fetch → normalize → filter → dedupe → notify)
lib/scraper.js           a single shared x-ray instance (HTTP + CSS extraction)
lib/store.js             lowdb JSON file, one array of seen IDs per source
lib/notify.js            single Telegram bot, single hard-coded chat ID
lib/logger.js            Winston, console + three rotating files
lib/utils.js             string/filter helpers
lib/sources/*.js         six provider definitions, auto-discovered from the directory
conf/config.json         the entire configuration, `require`d at module load
db/listing.json          the entire persistent state
```

### Boot sequence (`index.js`)

1. `rootpath` is installed so `require('lib/…')` resolves from the app root.
2. `conf/config.json` is `require`d. **A missing or malformed config crashes the
   process at import time**, before any error handling exists.
3. `loadSources()` reads every `.js` file in `./lib/sources` and `require`s it. A source
   that throws during load is logged and dropped; if *all* fail, exit code 1.
4. `INTERVAL = (config.intervalInMinutes || 5) * 60 * 1000`.
5. `setInterval(main, INTERVAL)` then an immediate `main()`.

### The cycle (`main()`)

- Guarded by a module-level `isRunning` boolean. If the previous cycle has not
  finished, the tick is **skipped entirely** (not queued).
- All sources run concurrently via `Promise.allSettled` — one failing source cannot
  abort the others, but a source that hangs holds `isRunning` and skips subsequent ticks.
- Counts successes/failures, logs duration. No metrics are persisted.

### Shutdown

`SIGINT`/`SIGTERM`/`uncaughtException` → clear the interval, flush Winston, exit.
If a cycle is in flight, it waits 30s then **force-exits with code 1** — it never
exits 0 after waiting, and it never actually re-checks whether the cycle finished.

---

## 2. The per-source pipeline (`lib/flatfinder.js`)

Each source is a `FlatFinder` instance built from a plain descriptor object:

| Field | Meaning |
|---|---|
| `name` | store key and log label; must be unique |
| `enabled` | `!!config.providers.<key>` — a provider is disabled by deleting its config entry |
| `url` | the fully-formed search URL (copy-pasted from the portal by the user) |
| `crawlContainer` | CSS selector matching one listing card |
| `crawlFields` | map of field → x-ray selector, with `|`-piped filters |
| `paginate` | CSS selector yielding the *next page URL* |
| `normalize(o)` | pure function reshaping the scraped record |
| `filter(o)` | predicate; `true` keeps the listing |

### `run()`

```
if !enabled          → return
listings = _getListings()                  ← HTTP + CSS extraction
knownSet = Set(store.knownListings)         ← O(1) membership
new      = listings.map(normalize)
                   .filter(filter)
                   .filter(o => !knownSet.has(o.id))
for each new listing (sequentially):
    msg = _formatListingMessage(listing)
    try   notify.send(msg); store.addListing(id)
    catch log failure;      store.addListing(id)   ← listing is dropped forever
    sleep random(1050, 2200) ms
```

Three consequences worth naming:

- **`normalize` is applied to the whole array with `Array.prototype.map` and is not
  guarded.** One malformed listing that throws inside `normalize` rejects the entire
  source run for that cycle. `immosuchmaschine.js:7` (`o.price.split('€ ')[1].split(',-')[0]`)
  and `wgGesucht.js:50` (`details[0].split(' in ')[1]`) both throw on unexpected input.
- **A failed notification still marks the listing as seen.** A transient Telegram
  outage silently and permanently loses listings.
- **The ID set is per-source, global, and unbounded.** It only ever grows.

### Pagination throttle

```js
this._fullCrawl = true
this._crawlCount = -1
if (paginate && (this._fullCrawl || (this._crawlCount++ % 10 === 0)))
```

Full paginated crawl (`.limit(20)` pages) on the first run; afterwards `_crawlCount`
post-increments from `-1`, so `-1 % 10 === -1` (falsy match), and the next full crawl
lands on the *third* run, then every tenth. Off-by-one, but harmless in practice.

### `debugRawHtml`

When enabled, the source is fetched **twice** — once as raw `html` for logging, then
again for extraction. `conf/config.json.example` ships with `"debugRawHtml": true`,
which doubles request volume and doubles bot-detection exposure for every user who
copies the example verbatim.

### Message format (`_formatListingMessage`)

```
*<title, asterisks stripped, truncated to 45 chars>*
📍 <address>
💶 <price>
📐 <size>
📐 <property_size>
🛌 <rooms>

[Link to offer](<link>) | [Google Maps](https://www.google.com/maps/search/?api=1&query=<address>)
```

Sent with legacy `parse_mode: 'Markdown'`.

**Latent bug:** only `*` is stripped from the title. A listing title containing `_`,
`[`, `` ` `` — common in German listing titles — produces unbalanced Markdown entities
and Telegram answers `400 Bad Request: can't parse entities`. Under the error handling
above, that listing is then marked seen and lost.

**Second latent bug:** `combineWhenGiven` tests `data !== undefined`. x-ray yields `''`
for a present-but-empty node, which renders as a bare emoji with no value. The address
is also interpolated into the Maps URL without `encodeURIComponent`.

---

## 3. Fetching (`lib/scraper.js`)

```js
Xray({ filters })
  .driver(makeDriver({ headers: { 'User-Agent': config.userAgent } }))
  .concurrency(Object.keys(config.providers).length)
  .delay(900, 1600)
  .timeout(10000)
```

- One shared x-ray instance across all sources. Concurrency equals the *number of
  configured providers*, which is not a meaningful throttle.
- The only header sent is `User-Agent`. No `Accept`, `Accept-Language`, `Referer`,
  no cookie jar, no HTTP/2, no TLS fingerprint control, no JavaScript execution.
- Available x-ray filters: `removeNewline`, `trim`, `int`.

`request-x-ray` wraps the deprecated `request` package and was last published
**2016-09-04**. `x-ray` itself was last published **2019-07-15**. Neither can execute
JavaScript, hold cookies across a redirect chain, or negotiate HTTP/2 — which is
precisely what every bot-protection layer now tests for. See `CRAWL-DIAGNOSIS.md`.

---

## 4. Storage (`lib/store.js`)

```js
db = low(new FileSync('db/listing.json'))
db.defaults({ [name]: [] }).write()
```

- A single JSON file, one array of seen listing IDs per source name.
- `addListing` rewrites the **entire file synchronously** on every single listing.
- `lowdb` is pinned to `^1.0.0`; current is `7.0.1`, and `.github/dependabot.yml`
  explicitly ignores major updates for it.
- No timestamps, no listing bodies, no per-user separation, no pruning, no schema,
  no concurrent-writer safety.

This file *is* the entire persistence layer. It is why two people cannot share one
deployment: the seen-set is global, so whoever is notified first suppresses the
listing for everyone else.

---

## 5. Notification (`lib/notify.js`)

```js
const bot = new TelegramBot(telegram.token)          // module-level, one token
bot.sendMessage(telegram.chatId, msg, { parse_mode: 'Markdown' })
```

- **One token, one chat ID, both read from config at import time.**
- On HTTP 429 it sleeps `retry_after + random(0,10)` seconds and retries **once**. Any
  other error propagates to `FlatFinder`, which marks the listing seen and moves on.
- `tg-yarl` was last published **2016-08-09**. It has no update loop, no webhook
  support, and no way to *receive* messages — the bot is send-only. This is the
  mechanical reason the chat ID has to be discovered manually with
  `curl .../getUpdates` and pasted into config before first run.

---

## 6. Configuration schema (`conf/config.json`)

```jsonc
{
  "debugRawHtml": false,
  "intervalInMinutes": 5,                    // default 5
  "userAgent": "Mozilla/5.0 …",
  "maxDistanceInKilometres": "10",           // string, compared numerically (immonet only)
  "wantedDistricts": ["Wedding", "…"],       // kleinanzeigen + wggesucht only
  "blacklist": ["swap", "tausch", "wg"],
  "telegram": { "token": "…", "chatId": "…" },
  "providers": {
    "immoscout":        { "url": "…" },
    "immonet":          { "url": "…" },
    "immowelt":         { "url": "…" },
    "kleinanzeigen":    { "url": "…" },
    "immosuchmaschine": { "url": "…" },
    "wggesucht":        { "city": "Berlin", "cityKey": 8, "minSize": 99, "maxRent": 9999 }
  }
}
```

Every field is global. There is no notion of *a search* — the config **is** the single
search, and the deployment **is** the single user.

### `.env.sample` is almost entirely dead

Traced every variable to its consumer:

| Variable | Read by | Status |
|---|---|---|
| `LOG_LEVEL` | `lib/logger.js:31` | ✅ live |
| `NODE_ENV` | `lib/logger.js:37` | ✅ live — raises the console transport to `warn` in production |
| `SCRAPING_INTERVAL_MINUTES=5` | nothing | ❌ dead — `index.js:8` reads `config.intervalInMinutes` |
| `DEBUG_RAW_HTML=false` | nothing | ❌ dead — sources read `config.debugRawHtml` |
| `MAX_CONCURRENT_SOURCES=3` | nothing | ❌ dead — `lib/scraper.js:31` uses `Object.keys(config.providers).length` |
| `REQUEST_TIMEOUT_MS=10000` | nothing | ❌ dead — hardcoded `.timeout(10000)` |
| `MAX_LOG_FILE_SIZE=5242880` | nothing | ❌ dead — hardcoded `maxsize: 5242880` |
| `MAX_LOG_FILES=5` | nothing | ❌ dead — hardcoded `maxFiles: 5` |

**Six of eight variables do nothing.** What makes this actively misleading rather than
merely untidy is that each dead variable's *value matches the hardcoded constant it
appears to control* — `5` minutes, `10000` ms, `5242880` bytes, `5` files. Setting
`REQUEST_TIMEOUT_MS=30000` looks like it will work, reads as though it worked, and
changes nothing. `MAX_CONCURRENT_SOURCES=3` is the one that is not even accurate as
documentation: real concurrency equals the number of configured providers, which is six.

Two settings live in `config.json` while their doppelgängers live in `.env.sample`, so
configuration is split across two files with one of them inert. The Elixir version
should have exactly one configuration surface — for a multi-tenant app that means
per-subscriber settings in the database and deployment settings in `runtime.exs`, with
nothing sample-shaped that does not resolve to a reader.

---

## 7. Filtering semantics (`lib/utils.js`)

```js
isOneOf(word, arr = []) → new RegExp(`\\b(${arr.join('|')})\\b`, 'ig').test(word)
```

- Whole-word, case-insensitive, applied to the raw string.
- **Terms are not regex-escaped.** A blacklist entry containing `(`, `|` or `?`
  corrupts the pattern or throws.
- **An empty array produces `\b()\b`, which matches any string containing a word
  boundary.** So an empty `blacklist` blacklists *everything*, and an empty
  `wantedDistricts` admits everything. The `wantedDistricts` direction is the benign
  one, which is likely why this survived (`1c9bdb8 fix: blacklist is ignored`).

`smallerEquals(int, ref)` returns `true` when either side is `undefined` — filters
fail open.

---

## 8. Provider matrix

The exact selectors in force today. Column *Status* is the live probe result from
`CRAWL-DIAGNOSIS.md` (2026-08-20).

### immoscout — `lib/sources/immoscout.js`
| | |
|---|---|
| Container | `#resultListItems .result-list__listing` |
| ID | `.result-list-entry@data-obid \| int` |
| Fields | price / size / rooms from `.result-list-entry__primary-criterion .grid-item:nth-child(n) dd`; title `.result-list-entry__brand-title`; link `…__brand-title-container@href`; address `.result-list-entry__address span` |
| Paginate | `.pagination [data-testid="pagination-button-next"]` — **no `@href`, so x-ray extracts text, not a URL** |
| Normalize | strips a hard-coded `NEU` `<span>` from the title, strips `(…),…` from address, prefixes `https://immobilienscout24.de` to the link |
| Filter | blacklist on title only |
| Status | **BLOCKED — HTTP 401, AWS WAF challenge** |

### immonet — `lib/sources/immonet.js`
| | |
|---|---|
| Container | `#result-list-stage div:not(#similar-objects-box, …) .item` |
| ID | `div[onclick^=try] a@id` → `parseInt(split('_')[1])` |
| Fields | price/size/rooms/property_size from `#keyfacts-bar div[id*="selPrice"]` etc. |
| Paginate | `.pagination-wrapper + a@href` |
| Normalize | splits `.box-25.ellipsis span.text-100` on `' • '` into 2 or 3 parts to derive `radius_distance`, `floor_type`, `address` |
| Filter | blacklist on title + description + floor_type, **plus** `radius_distance <= maxDistanceInKilometres` — the only consumer of that setting |
| Status | **DEAD — portal sunset, redirects to immowelt.de behind DataDome** |

### immowelt — `lib/sources/immowelt.js`
| | |
|---|---|
| Container | `div[data-testid="serp-core-scrollablelistview-testid"] [data-testid\|="serp-core-classified-card-testid"]` |
| ID | `div@data-testid` → `split('classified-card-mfe-')[1]` |
| Fields | `[data-testid\|="cardmfe-price-testid"]`, `…keyfacts-testid div:nth-child(3)` (size), `…description-box-text-test-id > div:nth-child(2)` (title), `a@href`, `…description-box-address` |
| Paginate | `[aria-label="nächste seite"]` — **no `@href`** |
| Filter | blacklist on title + description |
| Status | **selectors OK, URL scheme dead (410), pagination structurally impossible** |

### kleinanzeigen — `lib/sources/kleinanzeigen.js`
| | |
|---|---|
| Container | `#srchrslt-adtable .ad-listitem` |
| ID | `.aditem@data-adid \| int` |
| Fields | `.aditem-main--middle--price`, `.aditem-main--bottom p span:nth-child(1|2)`, `.text-module-begin a`, `.aditem-main--middle--description`, `.aditem-main--top--left` |
| Paginate | `#srchrslt-pagination .pagination-next@href` |
| Normalize | identity |
| Filter | blacklist on title + description **and** `wantedDistricts` must match the description |
| Status | **selectors all still valid, domain renamed** (`ebay-kleinanzeigen.de` → `kleinanzeigen.de`, old URLs 410) |

### immosuchmaschine — `lib/sources/immosuchmaschine.js`
| | |
|---|---|
| Container | `.result-list li` |
| ID | `.data_title div@data-expose-id` |
| Fields | `.data_price span`, `.data_size dd`, `.data_title div.objectLink`, link from `@data-js` (a JS tracking string, URL extracted by regex in `utils.extractUrlFromJavaScript`) |
| Paginate | `.link.next@data-href` |
| Normalize | `address.split(' • ')[0]`; `price.split('€ ')[1].split(',-')[0]` — **throws on any other price format** |
| Filter | blacklist on title + description |
| Status | **partially broken — `data-expose-id` no longer exists (now `data-id`)** |

### wgGesucht — `lib/sources/wgGesucht.js`
| | |
|---|---|
| Special | The only provider that **builds** its URL, from `city`/`cityKey`/`minSize`/`maxRent` + `wantedDistricts` → a 22-parameter query string. Exports **two** finders (`flatType` 1 = studio, 2 = normal flat) under one `run()` |
| Container | `#main_column .panel.panel-default:not(.panel-hidden):not(.noprint)` |
| ID | `@id` → `parseInt(split('-').pop())` |
| Fields | `.detail-size-price-wrapper .detailansicht` (size \| price), `.headline.printonly .detailansicht` (title + link), `.row p` (details) |
| Paginate | `nav .pagination li:last-of-type a@href` |
| Normalize | `details.split(' Verfügbar: ab ')[0].split(' in ')[1]` → address; `sizePrice.split(' | ')` → size, price |
| Filter | `wantedDistricts` must match address **and** blacklist on title |
| Status | **BROKEN — page redesigned; `.panel.panel-default`, `.detail-size-price-wrapper`, `.headline.printonly` all return 0 matches** |
| Note | `wgGesucht.js` exports `{ run }` with no `_source`, so `index.js:53` logs its name as `"Unknown"` |

---

## 9. Operations

- **Dockerfile:** `node:14-alpine`. Node 14 reached end-of-life **2023-04-30** and
  receives no security patches. Config and DB are bind-mounted.
- **CI:** `publish.yml` auto-tags and pushes multi-arch images to GHCR on every push
  to `master`. `security.yml` runs npm audit, Trivy, CodeQL, TruffleHog daily.
  Dependabot auto-merges patch/minor.
- **No test job exists, because there are no tests.**
- Winston writes `logs/app.log`, `logs/error.log`, `logs/scraping.log` with rotation.
  In production the console transport is raised to `warn`.

---

## 10. Behaviour worth preserving

1. Copy-paste a portal search URL; the tool crawls exactly that search. This is the
   product's best idea and must survive.
2. Per-source normalisation into a common `{id, title, address, price, size, rooms,
   link}` shape.
3. Whole-word, case-insensitive blacklist; district allow-list for the portals with
   weak native filtering.
4. Notify once per listing, never twice.
5. Sequential, jittered delivery so Telegram rate limits are not tripped.
6. Compact message with the emoji key-facts line and the Google Maps link.
7. Full paginated crawl occasionally, cheap first-page crawl usually.

## 11. Behaviour to break deliberately

1. One deployment = one user = one chat ID.
2. Configuration as a file that must exist before boot.
3. Dropping a listing permanently when notification fails.
4. A single malformed listing killing an entire source cycle.
5. Legacy Markdown without escaping.
6. Seen-state as an unbounded ID array with no listing data attached.
