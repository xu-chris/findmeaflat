# Phoenix and Frontend Implementation

**FindMeAFlat deltas only.** `deps/phoenix/usage-rules/*`, `deps/ash_phoenix/usage-rules.md`, and hexdocs `Phoenix.LiveView` / `Phoenix.Component` own general behaviour. No `docs/craft/` rule set exists yet, so there are no `WEB-00n` / `CSS-00n` ids to cite.

Project-specific reference only; inherit authority and scope from the calling skill.

Load for Phoenix, LiveView, HEEx, router, component, formatter, and frontend implementation. Route stable desired behavior through relevant Craft guides.

## Existing authorities

- `CODING_STANDARDS.md` focused-change scope governs O51; do not duplicate its prose.
- Frontend shared-component standards and `docs/craft/phoenix-liveview.md` WEB-008 govern O106; do not duplicate its prose.
- Focused-change standards and `docs/craft/dripfeed.md` govern O109; do not duplicate its prose.

## Project conventions

- All clickable elements use `<.button>`. Never introduce `<.link>`, `<a>`, or `<button>`.
- Add `:key` to template lists. Never load data in templates.
- Never render durable AI memory in ordinary user UI; expose it only to system workers and supermods.
- Inside `@layer`, replace failing `@screen xl` with `@media (min-width: 80rem)`.
- Tailwind `xl:calc(...)` plus `var()` needs spaced operators. Use plain CSS `@media` plus `calc()`.
- `<.button>` `class` accepts a string; build one string, never a list.
- Inside `<.form>`, set every non-submit `<.button>` to `type="button"`.
- Use colocated hooks only. Never edit `app.js` or add an npm package. Test for `phx-hook` presence, not an unnamespaced local hook value.
- Reuse `translations/` modules injected by `use FindMeAFlatWeb, :live_view`; never duplicate them as `defp`.
- Align through a shared parent. Never fake indent with magic padding.
- AshPhoenix form flow is `for_create/3` then `submit/2`; on `{:error, form}`, apply `to_form/1`.
- Embedded-form `auto?: true` registers configuration only; call `add_form/2` to instantiate it. A missing singular embedded form is `nil`, not a collection.
- A non-Ash field uses raw `name="work[field]"` plus `value={@assign}`; `transform_params` strips it.

## Rules

- Standalone `<.field>` calls using `name` instead of a form `field` must pass an explicit `value`.

- `use FindMeAFlatWeb` and `use FindMeAFlatWeb.Components` import only configured components; verify each optional component import, import it explicitly, and use fully qualified module names rather than aliases for direct module calls.

- LiveView function components do not inherit parent `@streams`; pass each stream as an explicit assign.

- Before adding `get`/`live` under an existing prefix like `/dev`, search the router for conflicts. Example: `error_tracker_dashboard("/errors")` owns `/dev/errors/:id`; `/dev/errors/:status` shadows it. Run `mix compile --force --warnings-as-errors`; incremental compile misses clause shadowing.

- When retiring a LiveView action, remove its now-unused state-reset helper in the same change; `--warnings-as-errors` catches the orphan.

- LineUp visualizations need real date ranges; do not feed milestone/point events directly unless deliberately rendering tiny point markers.

- Moving private helper logic between LiveView modules/components: move or duplicate every called private helper before reloading the page.

- After renaming a component assign, grep for the prior name across every render variant before compiling.

- `Phoenix.Router.__routes__/0` stores LiveView route data in `route.metadata[:phoenix_live_view]`; filter non-Live routes before destructuring.

- When `Code.eval_quoted/3` injects optional router macros that expand nested Phoenix scopes, pass the router's `__ENV__`; default evaluation loses imports such as `scope/3`.

- Storybook slot/template heredocs containing runtime HEEx interpolation must use `~S` or escape `#{...}`; plain heredocs interpolate while compiling the story module. Story paths preserve filename underscores; inspect backend leaves before asserting a load path.

- Keep local components used by embedded templates private once consumed; public self-references can invoke Phoenix verification before the owning module is available.

- Before `start_async/3`, bind every needed socket assign to a local variable; never capture `socket` inside the async function.

- Remove Phoenix component `attr` declarations when replacing an arity-one component with a regular helper.

- Remove competing Tailwind padding utilities when adding `auto-layout`; cascade order can keep fixed padding active.

- Before using dependency-prefixed utility classes in extension tuples, verify the exact class exists in compiled dependency CSS; Tailwind emits only scanned classes.

- `Phoenix.Component.embed_templates/2` appends configured engine extensions; pass a pattern such as `brand/*`, never one already ending in `.heex`.

- Before naming a wrapper function in a module importing a component facade, check imported names and arities; use a role suffix such as `_page` to avoid local-function conflicts.

- When replacing a form block, include every sibling field in patch context before swapping wrapper components.

- LiveComponent actions needing page-level toast feedback must message the parent LiveView; component-local `put_toast/3` does not render through the parent layout.

- Phoenix/Plug dynamic route segments cannot carry suffixes such as `:token.ics`; put the extension in a separate static segment.

- Pass non-HTTP links to `Phoenix.Component.link/1` as a scheme tuple such as `{:webcal, "//host/path"}`; scheme safety validation applies to raw strings and parsed URIs alike.
