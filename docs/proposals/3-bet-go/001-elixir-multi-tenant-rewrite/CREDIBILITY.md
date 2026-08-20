# Credibility and Scam Detection

Rental scams are endemic on exactly the portals this crawler reads — ImmoScout24,
WG-Gesucht and Kleinanzeigen are the ones consumer advice repeatedly names. A tool that
sees every new listing across six portals within minutes is in an unusually good
position to score them, because most of the published warning signals are **computable
from data the crawler already collects.**

---

## 1. The insight that makes this cheap

The fair-rent feature computes one number: **deviation from the Mietspiegel reference
rent.** `PRODUCT-VISION.md` §2.1 uses the positive tail — a flat at +66 % over reference
is an exploitation signal, possibly a Mietpreisbremse breach.

**The negative tail is the single strongest scam signal there is.** Every consumer
warning list opens with the same item: *auffällig niedrige Miete*, *besonders günstige
Mieten in Top-Lage*. A 90 m² flat in Prenzlauer Berg at 600 € warm is not a bargain, it
is bait.

```
        SCAM                    FAIR                  EXPLOITATION
 ←───────────────────┼───────────────────────┼───────────────────→
      −40 %        −20 %      reference     +10 %              +50 %
   "too good                              Mietpreisbremse
   to be true"                              threshold
```

One computation, one Mietspiegel join, two features at opposite ends of the same axis.
That is the whole architectural argument for building credibility scoring alongside the
fair-rent check rather than as a separate subsystem — and it means the scam feature is
nearly free once Phase 3 lands.

---

## 2. Signals, and whether we can actually see them

Sorted by what the crawler can determine on its own. This distinction matters: the
strongest *consumer* warnings are about what happens after contact, and we see none of
that.

### Tier A — computable from crawled data alone

| Signal | Source | Strength |
|---|---|---|
| **Rent far below Mietspiegel reference** | fair-rent computation, negative tail | **Very high** |
| **Photo reuse across listings** | perceptual hash (pHash) of listing images | **Very high** |
| **Description text reuse** | normalised text hash / shingling | High |
| **External link in description** | URL extraction — "ein externer Plattformlink" is a named signal | High |
| **Scam-vocabulary keywords** | `Vorkasse`, `Kaution vorab`, `Schlüsselversand`, `im Ausland`, `Reservierungsgebühr`, `Besichtigungsgebühr`, `Schlüsselpfand`, `ohne Besichtigung` | High |
| **No viewing offered / viewing discouraged** | phrase matching | Medium |
| **Provider unknown to us** | own `Provider` history | Medium |
| **Listing reposted repeatedly** | own listing history on `{address, provider}` | Medium |
| **Address vague or missing** | structured address completeness | Low–medium |
| **Contact pushes off-platform** | e-mail/phone/WhatsApp in the description body | Medium |

**Photo reuse deserves emphasis, because crawling six portals is what makes it work.**
A scammer lifts photos from a genuine listing — often one currently live on a *different*
portal. Single-portal tools cannot see that; a cross-portal crawler with a pHash index
can. Same for text reuse. This is a capability that emerges from the existing
architecture rather than needing new data.

### Tier B — visible only after contact, so out of scope

Payment demanded before viewing, foreign bank account, pressure to transfer quickly,
"I'm abroad, I'll post the keys", a contract that never arrives. These are the signals
consumer advice leads with, and **the crawler never sees any of them.** The honest
product response is not to detect them but to *warn about them* — a short "what to
watch for" note attached to any listing scoring above a threshold, pointing at the
Verbraucherzentrale. Cheap, useful, and it does not overclaim.

### Tier C — deliberately not built

Contacting listings to probe for scam behaviour. That is active engagement with third
parties under false pretences, and `OPEN-DATA.md` §6 already rules out automated
contact for unrelated reasons.

---

## 3. Scoring

**Not** a single opaque number. A small set of independent, individually-explainable
flags, each with a reason string the bot can print.

```elixir
%CredibilityAssessment{
  listing_id: …,
  score: 0.82,                     # 0.0 trustworthy → 1.0 almost certainly fraudulent
  band: :high_risk,                # :ok | :caution | :high_risk
  flags: [
    %{kind: :price_far_below_reference, weight: 0.45,
      detail: "6,45 €/m² vs. Mietspiegel-Referenz 14,10 €/m² (−54 %)"},
    %{kind: :photo_reuse, weight: 0.30,
      detail: "3 Bilder identisch mit Inserat auf immowelt (ID 12345), erfasst am 12.08."},
    %{kind: :scam_vocabulary, weight: 0.15,
      detail: "Text enthält „Kaution vorab\" und „befinde mich im Ausland\""}
  ],
  computed_at: ~U[…]
}
```

Rules from the outset:

- **Every flag is explainable in one German sentence.** A user shown "risk: 0.82" learns
  nothing. A user shown "these three photos also appear in a listing on Immowelt from
  last week" can act immediately.
- **Weights start hand-tuned and stay visible.** No model until there is labelled data,
  and there is no labelled data yet. Hand-tuned weights are honest and debuggable;
  a classifier trained on nothing is neither.
- **Never state a listing *is* a scam.** State the observation. "Diese Wohnung ist Betrug"
  is a factual claim about a named third party that could be wrong and defamatory;
  "Der Preis liegt 54 % unter dem Mietspiegel und drei Bilder erscheinen in einem anderen
  Inserat" is an observation the user judges. This distinction is not pedantry — it is
  the difference between a useful warning and a liability.
- **Score, do not suppress.** A high-risk listing is still delivered, with its warning
  attached. Silently filtering means a false positive costs the user a real flat and
  they never learn it happened.

In the Telegram message:

> ⚠️ **Vorsicht — mehrere Warnsignale**
> · Preis 54 % unter Mietspiegel-Referenz
> · 3 Bilder erscheinen in einem anderen Inserat (immowelt, 12.08.)
> · Text enthält „Kaution vorab", „befinde mich im Ausland"
> 💡 Nie Geld überweisen vor Besichtigung und unterschriebenem Vertrag. [Verbraucherzentrale](…)

---

## 4. What this needs that Phase 1 does not have

| Requirement | Note |
|---|---|
| Listing **images** stored or hashed | Phase 1 currently parses no image URLs. **Add image URL extraction to the selector sets now** — re-crawling later is impossible, the listing will be gone |
| Perceptual hashing | pHash/dHash over fetched thumbnails. No mature Elixir library; likely a small NIF, a port, or `Image`/`vix`. Investigate before committing |
| Full description text stored | Phase 1 already stores `raw` — ensure descriptions are captured, not truncated |
| Mietspiegel reference | Phase 3 |
| `Provider` history | Phase 4 |

**The one thing Phase 1 must do is capture image URLs and full description text.**
Everything else can be computed later from stored data; these two cannot be recovered
once a listing is delisted. This is the same argument as `PRODUCT-VISION.md` §4 —
capture is cheap now and impossible later.

Storing image *thumbnails* rather than just URLs is worth considering, since scam
listings get taken down fast and the URLs die with them. That has storage and copyright
implications; hashes alone may be the better trade — a hash is not a reproduction.

---

## 5. Where this gets uncomfortable

**False positives have real cost.** A genuinely cheap flat — a Genossenschaft, a
long-term tenant subletting at their old rent, a WBS-bound unit — will trip the
price-below-reference flag hard. These are exactly the flats a renter most wants. If the
warning is loud, the tool teaches users to skip the best listings on the market.

Mitigations: never suppress, always explain, weight photo-reuse and vocabulary higher
than price alone, and treat *price-below-reference on its own* as `:caution` rather than
`:high_risk` — one signal is a question, three signals is an answer.

**Accusing named companies is a legal exposure.** A flag attached to a listing from a
named Hausverwaltung is a public-ish statement about that business. Observations, not
verdicts, and no aggregate "scam ranking" of named providers without a much higher
evidentiary bar than this design provides.

**Scammers adapt.** A published scoring model is a specification for evading it. Keep
the weights internal, and never document the exact thresholds in user-facing text.

---

## Sources

- [Verbraucherzentrale – Wohnungsbetrug 2026: Fake-Inserate erkennen](https://www.verbraucherzentrale-finanzen.org/wohnungsbetrug-warnung/)
- [Mietrecht-Ratgeber – Wohnungsbetrug erkennen: 15 Warnsignale](https://www.mietrecht-ratgeber.de/nachrichten/wohnungsbesichtigung-und-betrug-15-warnsignale-bei-fake-inseraten)
- [Netkredit24 – Fake-Wohnungsanzeigen erkennen: Warnsignale](https://www.netkredit24.de/blog/fake-wohnungsanzeigen-erkennen-warnsignale-vor-der-ueberweisung/)
- [nord24 – Wohnungssuche: Betrugsmaschen bei Wohnungsbetrug](https://www.nord24.de/verbraucher/wohnungssuche-betrugsmaschen-wohnungsbetrug-372786.html)
- [Living in Berlin – Mietbetrug erkennen](https://www.livinginberlin.de/blog/mietbetrug-erkennen-so-filtern-sie-unserioese-angebote-aus/)
