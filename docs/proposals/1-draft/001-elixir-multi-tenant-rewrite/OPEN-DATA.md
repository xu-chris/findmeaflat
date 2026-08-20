# Open Data Feasibility — Mietspiegel, Buildings, Hausverwaltung

You said the Mietspiegel is "probably open data, I need to check". I checked. Short
answer: **partly, and the gap is coverage, not technology.**

All probes run **2026-08-20**.

---

## 1. What a Mietspiegel actually is (and why this matters for the data model)

A common misreading is that the Mietspiegel is one €/m² number per district. It is not.
It is a **multi-factor model**, and the Dortmund open dataset shows the real shape.
Here is one genuine record from
`https://open-data.dortmund.de/api/explore/v2.1/catalog/datasets/fb64-mietspiegel-2025-2026/records`:

```json
{
  "stadtbezirk": "Innenstadt-Nord",
  "unterbezirk": "Nordmarkt-West",
  "mietspiegelgebiet": "Innenstadt-Nord",
  "wohnflachenklasse": "50,01-60,00 m²",
  "baualtersklasse": "1910-1934",
  "anderungskonstellationen": "Bestandsmiete - keine Mieterhöhung, keine Ausstattungsänderung",
  "nettokaltmiete_eur_m2": 4.61,

  "badezimmer_mit_dusche": "nein",
  "warmeschutzverglasung": "ja",
  "etagenheizung": "ja",
  "kein_balkon_keine_loggia_keine_terrasse": "nein",
  "wohnung_uber_einen_aufzug_erreichbar": "nein",
  "barrierearme_erstellung_oder_modernisierung": "nein",
  "fussbodenheizung": "nein",
  "parkettboden_oder_aufgearbeitete_hobeldielen": "nein",
  "baderneuerung_ab_2015": "nein",
  "…~25 Ausstattungsmerkmale total…"
}
```

2,443 records. So the reference rent is:

```
nettokaltmiete_eur_m2 = f(Mietspiegelgebiet, Wohnflächenklasse, Baualtersklasse, ~25 Ausstattungsmerkmale)
```

Three consequences for the product:

1. **Location + size + building age get you into the right cell. The equipment features
   move the number substantially** — a balcony, an elevator, parquet, a 2015 bathroom
   renovation each carry their own surcharge. A comparison that ignores them will
   overstate how overpriced a good flat is and understate a bad one.
2. **The listing text is the only source for most equipment features**, and it is
   unreliable, incomplete and marketing-shaped. This is the accuracy ceiling of the
   whole feature, and it should be stated to the user rather than hidden.
3. **Building age is a first-class input**, which is why your instinct to pull building
   age is right — it is not a nice-to-have, it is one of three axes of the base table.

---

## 2. Coverage — the actual constraint

`GET https://www.govdata.de/ckan/api/3/action/package_search?q=Mietspiegel` → **41 datasets nationally**.

Filtering out duplicates, draft legislation and unrelated statistics, what actually
exists as machine-readable Mietspiegel data:

| City | What is published | Usable? |
|---|---|---|
| **Dortmund** | Full Mietspiegel table 2025-2026, Opendatasoft API, 2,443 rows with €/m² | **Yes — best in class** |
| **Berlin** | *Wohnlagen per address* (WFS, 2003→2026) — the location axis only, not the rent table | **Partly** |
| Wuppertal | Wohnlagen + georeferenced addresses with Wohnlage | Partly |
| Hamm | Wohnlage | Partly |
| Rastatt, Ettlingen, Rheinstetten, Baden-Baden | Mietspiegel datasets | Small cities |
| **München** | Only **1994** and **2003** Mietspiegel | **No — current data not open** |
| **Hamburg, Köln, Frankfurt, Stuttgart, Leipzig, Dresden** | Not in the index | **No** |

Meanwhile the BBSR reports that as of 2025-12-31 Mietspiegel are **near-universal in
municipalities over 50,000 inhabitants**. So nearly every relevant city *has* one — it
is published as a **PDF brochure**, not as data.

**This is the honest headline: the Mietspiegel exists nearly everywhere and is open
data almost nowhere.** The engineering problem is not access, it is that reaching
national coverage means digitising PDF tables city by city. That is a slow, manual,
unglamorous data-entry effort — and it is also the actual moat, because nobody else
wants to do it either.

Sensible sequencing: **Berlin and Dortmund first** (real data, and Berlin is where you
and the users are), a hand-digitised table per city after that, driven by demand.

---

## 3. Berlin specifically — two sources, one of them address-level

Berlin splits the model across two datasets, and the address-level one is the
interesting half.

**(a) Wohnlagen nach Adressen — the location axis, per building address**

- Endpoint: `https://gdi.berlin.de/services/wfs/wohnlagenadr2026`
- Licence: **Datenlizenz Deutschland – Zero – Version 2.0** — the most permissive
  German public licence. Commercial use allowed, no attribution legally required.
- Published 2026-05-28, valid to 2028-05-28.
- Classifies **every Berlin address** as `einfach` / `mittel` / `gut`.
- Historical series back to 2003, so rent trajectories per address are derivable.

This is precisely the "map every house in the city" capability you described. It is
already done, officially, per address, and free to use commercially.

**(b) The Mietspiegel rent table itself** — Baualtersklasse × Wohnflächenklasse ×
Wohnlage → €/m² range. Published as a PDF brochure, **not** as an API. One-time manual
digitisation of roughly a 100-cell table, re-done every two years. Small and tractable.

**Probe result — and a lesson worth repeating.** At probe time every Berlin GDI
endpoint returned:

```
status=200  size=1411  →  <title>Wartungsarbeiten</title>
```

**HTTP 200 with a maintenance page.** Not a 503, not a 500. The service is real and
documented, it was simply down — but a naive client would have parsed that as a valid
empty response and cached zero Wohnlagen for all of Berlin.

This is the same failure mode as `CRAWL-DIAGNOSIS.md`: *a 200 is not a success.* The
ingestion pipeline must validate shape, not status, and refuse to overwrite good data
with an empty result. Note it and move on — the endpoint is fine.

**(c) Gebäudealter der Wohnbebauung (Umweltatlas)** — building age, WFS, last updated
2026-02-04. Important caveat found in the metadata: it is **block and block-segment
based at 1:5,000 (ISU5)**, giving the *predominant* age class per block, not per
building. Good enough for the Baualtersklasse axis. Not good enough for "this specific
house was built in 1904".

**(d) OpenStreetMap** as a supplement. Overpass is up (22 slots free). A sample query
over a Berlin block returned buildings with genuine `start_date` tags — but look at the
values: `'1838'`, `'~1890'`, `'1712..1713'`. **Sparse coverage and messy formats**
(approximation markers, ranges). Usable as a secondary hint with a confidence score,
never as the primary source. OSM also carries `building:levels`, `addr:*` and
occasionally `heritage` / `ref:lda` (Denkmalschutz) — Denkmalschutz status is
genuinely useful to a renter and is a nice differentiator.

---

## 4. Mietpreisbremse — why the comparison is actionable

- Extended to **31 December 2029**; applies in **800+ municipalities**, including every
  large city.
- On a new letting in a tight market, rent may not exceed the **ortsübliche
  Vergleichsmiete + 10 %**.
- The ortsübliche Vergleichsmiete is normally established **by the local Mietspiegel** —
  the exact dataset above.

So "this listing is 23 % above the local reference rent" is not trivia. It is a
concrete, legally-grounded signal that a renter can act on, and no portal will ever show
it because it is against the portals' interests.

**Framing matters.** Presenting a computed verdict — *"this violates the
Mietpreisbremse"* — is effectively legal advice, from a number derived from equipment
features guessed out of listing prose. The defensible framing is informational:

> 💶 1.450 € kalt · 62 m² → **23,39 €/m²**
> 📊 Mietspiegel-Referenz (Wohnlage *gut*, Baujahr 1900–1918, 60–70 m²): ~14,10 €/m²
> ⚠️ **+66 % über der Referenz.** Ab +10 % kann die Mietpreisbremse greifen.
> Schätzung aus Inseratsangaben — verbindlich prüft das der Mieterverein.

State the inputs, state the uncertainty, point at someone qualified. That is both more
honest and more useful than a verdict.

---

## 5. Hausverwaltung — the hard one

Your reasoning is sound: reaching the manager by phone beats being message #47 in a
platform inbox. The data question is where the number legitimately comes from.

**Closed — do not build on these:**

- **Grundbuch (land register).** Not public. §12 GBO requires a demonstrated
  *berechtigtes Interesse* per enquiry. Not automatable, and attempting it at scale is
  not a grey area.
- **Klingelschild / on-site.** Not remotely accessible.

**Open — build on these:**

| Source | Yields | Notes |
|---|---|---|
| **The listing itself** | Anbieter name, often the Verwaltung, sometimes a phone number | Already in the HTML the crawler fetches. Cheapest and best signal by far |
| **Impressum of the Anbieter's site** | Company name, address, phone, managing director | §5 DDG makes this **legally mandatory and public**. This is the intended route |
| **Handelsregister / Unternehmensregister** | Legal entity, address, officers | Public register, company data |
| **OSM `office=property_management`** | Some managers geocoded | Sparse but free |
| **Own accumulated crawl history** | "This Verwaltung has listed 43 flats in Wedding" | Emerges from your own data over time — and this is the genuinely defensible asset |

**The GDPR line, drawn clearly.** A GmbH's Impressum phone number is company contact
data, and aggregating it is ordinary business practice. A **private individual
landlord's** name and number is personal data under GDPR, and building a searchable
database of those triggers Art. 6 (legal basis, with a balancing test) *and* Art. 14 —
the duty to **proactively inform each person** whose data you collected indirectly.
Art. 14 is not realistically satisfiable for scraped landlord data at scale.

**Recommendation: store commercial providers only.** Classify the Anbieter; if it is a
company, keep it and enrich it. If it is a private individual, keep the listing but
store no contact record. This costs little — private landlords are the minority of
listings and the ones *least* likely to be reachable via a Verwaltung anyway — and it
keeps the whole feature on the right side of a line that would otherwise be a serious
liability for a tool with real users in Germany.

---

## 6. The auto-reply idea — worth separating into three

You raised three distinct mechanisms. They have very different risk profiles, and I
would not treat them as one feature.

**(a) Be fast — legitimate, and the strongest version.** Landlords stop reading after
roughly the tenth message. The winning move is not automation, it is **latency**: a
2-minute crawl interval plus an instant push means the user is message #3, not #47. The
bot can hand them a pre-filled, well-structured message to paste — the Mietercoach
advice is that a complete, individual first message measurably raises response rates,
and the bot already knows the flat's details and can merge them into the user's own
template. **The user still presses send.** This needs no platform automation, breaks
no terms, and directly attacks the actual problem.

**(b) Auto-submitting the contact form — do not build.** Three independent reasons:
the portals' terms forbid automated interaction; ImmoScout24's contact flow sits behind
the same AWS WAF challenge the crawler cannot pass; and if the tool is popular in
Germany, mass auto-replies make the flooding measurably worse for every renter,
including your users. It is an arms race whose end state is worse for everyone and in
which landlords start ignoring platform messages entirely.

**(c) Delayed re-sending to bump to the top — do not build.** This is deliberately
gaming the platform's message ordering. It also does not work socially: landlords see a
duplicate message from the same person and read it as pushy, not persistent.

**(d) Calling the Hausverwaltung — build this, it is the real idea.** It is the one
mechanism here that is entirely legitimate, entirely outside the platforms' control,
and genuinely differentiating. Nobody else offers it. A message that ends with

> 🏢 Verwaltet von **Meier Immobilienverwaltung GmbH** · ☎️ 030 12345678
> *12 weitere Inserate in Wedding in den letzten 90 Tagen*

is more valuable than any automated reply would have been, and it turns your crawl
history into an asset rather than a byproduct.

---

## 7. Summary of what is buildable

| Capability | Data exists? | Effort | Verdict |
|---|---|---|---|
| Wohnlage per address, Berlin | **Yes** — WFS, dl-de/zero-2.0, per address | Low | **Build** |
| Full Mietspiegel table, Dortmund | **Yes** — API, 2,443 rows | Low | **Build** |
| Mietspiegel, other cities | PDF only | High, manual, per city | Demand-driven |
| Building age, Berlin | Yes — block level, not building level | Medium | Build, state the granularity |
| Building age, OSM | Sparse, messy formats | Low | Secondary hint only |
| Denkmalschutz status | Yes, in OSM for Berlin | Low | Nice differentiator |
| Rent vs. reference comparison | Derived from the above | Medium | **Build — the flagship feature** |
| Mietpreisbremse flag | Derived | Low | Build, informational framing only |
| Hausverwaltung, commercial | Listing + Impressum + Handelsregister | Medium | **Build** |
| Hausverwaltung, private landlords | GDPR Art. 14 blocker | — | **Do not build** |
| Provider history / reputation | Own crawl data | Low, accrues over time | **Build — compounding asset** |
| Auto-reply to listings | — | — | **Do not build** |
| Pre-filled message for the user to send | — | Low | **Build** |

---

## Sources

- [Wohnlagen nach Adressen zum Berliner Mietspiegel 2026 – WFS](https://daten.berlin.de/datensaetze/wohnlagen-nach-adressen-zum-berliner-mietspiegel-2026-wfs-809faebe)
- [Berlin Open Data – Mietspiegel datasets](https://daten.berlin.de/datensaetze?tags=Mietspiegel)
- [Gebäudealter der Wohnbebauung (Umweltatlas) – WFS](https://daten.berlin.de/datensaetze/geb%C3%A4udealter-der-wohnbebauung-umweltatlas-wfs)
- [Mietspiegel 2025-2026 Fortschreibung – Open Data Dortmund](https://open-data.dortmund.de/explore/dataset/fb64-mietspiegel-2025-2026/?flg=de-de)
- [Mietspiegel 2025-2026 – Open.NRW CKAN](https://ckan.open.nrw.de/dataset/mietspiegel-2025-2026-fortschreibung-rvr)
- [BBSR – Mietspiegel in Deutschland, Verbreitung 2025](https://www.bbsr.bund.de/BBSR/DE/daten-karten/wohnen-immobilien/2025/mietspiegelverbreitung-2025.html)
- [Deutscher Bundestag – Mietpreisbremse bis 2029 verlängert](https://www.bundestag.de/dokumente/textarchiv/2025/kw26-de-mietpreisbremse-1084786)
- [Finanztip – Mietpreisbremse: So hoch darf die Miete sein](https://www.finanztip.de/mietpreisbremse/)
- [Mietercoach – Anfragen auf Immoscout, Immowelt & Co richtig formulieren](https://mietercoach.de/2021/01/24/endlich-antwort-vom-vermieter-erhalten-anfragen-auf-immoscout-immowelt-co-richtig-formulieren/)
- [Immowelt Support – Die Vermieter antworten mir nicht](https://support.immowelt.de/hilfekontakt/suchender/immowelt-app/die-vermieter-bzw-verkaeufer-antworten-mir-nicht-woran-liegt-das/)
- [Haufe – Die DSGVO in der Immobilienverwaltung](https://www.haufe.de/immobilien/wirtschaft-politik/dsgvo-fokus-auf-hausverwaltung-immobilienverwaltung-weg/die-dsgvo-in-der-immobilienverwaltung_84342_639396.html)
