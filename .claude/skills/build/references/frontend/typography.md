# Typography — detail

Loaded from [interface.md](interface.md) for font delivery, OpenType features, wrapping, or bidirectional text.

**FindMeAFlat deltas only.** No `docs/craft/css.md` exists yet — treat this file as the rules. General behaviour is owned by the MDN font and text docs.

---

## fonts-and-opentype

# Fonts and OpenType

Inspect current font declarations and assets before proposing a change. Prefer WOFF2, truthful family/style/weight descriptors, and only the script subsets the product can safely serve. Preload only a font needed in the first rendered view; extra preloads compete with application assets.

Choose `font-display` from the product consequence and test the fallback swap. Tune fallback metrics when layout shift is material rather than hiding it behind a long invisible-text period. Do not disable synthesis unless the required weights and styles exist.

For variable fonts, declare the real supported ranges. Use high-level properties for registered axes: `font-weight` for `wght`, `font-stretch` for `wdth`, `font-style` for italic/slant. Use `font-variation-settings` only for custom axes or precision high-level properties cannot reach. Optical sizing helps only when the font supports it and rendered roles have been compared.

Prefer high-level OpenType controls such as `font-variant-numeric: tabular-nums`, ligature, small-cap, and East Asian variants. Use `font-feature-settings` as a low-level escape hatch, not as a replacement for semantic properties. Verify fallback fonts; unsupported features fail differently.

Check loaded network assets, requested versus available faces, synthetic fallback, layout shift, missing glyphs, diacritics, and each enabled axis/feature at final rendered sizes.

---

## wrapping-and-bidi

# Wrapping, Truncation, and Bidirectional Text

Use `text-wrap: balance` for short headings only where uneven final lines benefit; use prose-oriented wrapping where supported and keep a normal fallback. `overflow-wrap: anywhere` is a last-resort protection for unbroken identifiers or URLs, not a default for prose. Hyphenation needs truthful language metadata and language-specific testing.

Do not insert manual line breaks to force one viewport composition. Test long German listing titles, compound street names, portal URLs, euro amounts, and portal-authored content at narrow widths and larger text.

Single-line ellipsis and multi-line clamping hide content. Use them only when the complete value stays reachable through expansion, detail navigation, an accessible label/description, or adjacent source. Do not rely on an unannounced hover-only tooltip.

Use semantic underlines for links and keep descenders legible through offset/thickness behavior. Selection, placeholder, and caret colors need real background contrast; text stays selectable unless a proven gesture conflicts.

Set document and fragment language correctly. Use `dir="auto"` or a deliberate direction boundary for user-authored text, and `<bdi>` or CSS isolation around mixed-direction identifiers, dates, URLs, and names. Do not infer text direction from interface locale alone. Verify punctuation placement and numeric sequences in both LTR and RTL surroundings.
