# Color — detail

Loaded from [interface.md](interface.md) for OKLCH work, contrast verification, palette generation, or gamut questions.

**FindMeAFlat deltas only.** No `docs/craft/css.md` exists yet, so there is no `CSS-006` to cite — treat this file as the rules. General behaviour is owned by MDN `color()` / `oklch()`. **No frontend exists yet; the only planned surface is the admin console.**

---

## accessibility-contrast

# Contrast Evidence

WCAG 2.x contrast rules conformance whenever FindMeAFlat claims WCAG. Measure normal text, large text, graphical objects, control boundaries, and focus indicators against the published threshold. APCA may add perceptual evidence; it never replaces a required WCAG 2.x result.

Measure rendered foreground/background pairs, not tokens alone. Resolve transparency, gradients, images, overlays, disabled and placeholder states, hover/focus/selected states, both appearances, and forced colors. A focus indicator may cross several adjacent colors; inspect all of them.

Report pair, state, method, value, and missed threshold before proposing a change. Once repair is authorized, adjust OKLCH lightness first, preserve semantic hue where possible, cut chroma when gamut demands it, then remeasure every affected appearance. Mid-lightness surfaces may need both roles changed rather than one color pushed to an extreme.

Do not use an approximate lightness gap, token name, or passing neighboring pair as proof.

---

## color-conversion

# Color Conversion

Convert only when accepted color-system work or an explicit request demands it. Do not normalize isolated third-party or deliberately fixed values as cleanup.

Support hex, RGB(A), and HSL(A) inputs; preserve alpha with modern slash syntax. Use a trusted color implementation, not hand calculations, keep round-trip precision, and compare rendered output.

Leave CSS keywords such as `currentColor`, `transparent`, `inherit`, and system colors alone. Convert gradient stops without changing interpolation, geometry, or stop order. Keep external configuration in the notation its API requires.

For a bounded bulk conversion, inventory every declaration and dynamic source, preserve comments and formatting, verify no unsupported notation slipped through, then check contrast and gamut against actual semantic use. Conversion alone does not make a palette accessible or well designed.

---

## palette-generation

# Palette and Gamut Work

Generate only the primitive steps and semantic roles the accepted design needs. Numeric 50–950 scales are not FindMeAFlat's architecture and must not be recreated merely because another framework used them.

Choose a base hue and intended lightness/chroma behavior. Distribute lightness deliberately, then find the maximum in-gamut chroma per lightness and hue in the target space. Light and dark ends normally carry less chroma. Equal absolute chroma across hues does not mean equal perceived vividness.

Provide an sRGB-safe value first. Add Display-P3 only when target support and visual value justify it, with explicit gamut checks and fallback ordering. Verify hue drift after gamut mapping.

Map stable primitives to semantic roles. Design dark appearance by remapping and tuning roles, not by reversing a ramp. Check every foreground/background pair in both appearances and keep `color-scheme` aligned for native controls.

Return the intended roles, generation method, gamut target and fallback, sampled lightness/chroma/hue behavior, contrast matrix, and any pair that needed manual tuning.
