# Igniter Scripts

Read only when building a reusable generator, registration, migration, rename, or AST-refactor Mix task. A one-off edit does not need Igniter.

**FindMeAFlat deltas only.** `deps/igniter/usage-rules.md` and hexdocs `Igniter` / `Igniter.Project.*` / `Igniter.Code.*` own general behaviour. There is no `docs/craft/deterministic-changes.md` in this repository.

# Writing Igniter Scripts

Build deterministic, idempotent project changes with Igniter. Prefer semantic AST navigation and existing Igniter tasks over source-string manipulation.

## Authority

Inherit the write boundary from the caller. This skill authorizes no dependency change, package installation, issue, commit, push, or agent-skill edit. Route durable agent-system learning through `craft-skills`.

## Mandatory Workflow

1. Read project `AGENTS.md` and `deps/igniter/usage-rules.md`.
2. Verify APIs against installed Igniter docs or source. Never copy remembered API names from another version.
3. Search built-in and project-local Igniter tasks. Use a suitable existing generator instead of reproducing its output by hand.
4. Decide whether the change establishes repeatable scaffolding or a consistency contract. If yes, create or extend a generator before producing instances.
5. Generate custom tasks with `mix igniter.gen.task`.
6. Locate code semantically. Mutate quoted AST. Make every operation idempotent.
7. Test missing, initial, conflicting, and already-applied source shapes.
8. Run the custom task with `--dry-run`. Review the diff, then apply.
9. Customize generated files only after baseline generation, never bypassing owned registration or metadata.
10. Format changed code. Rerun the dry-run. Require no proposed content changes.
11. Compile and run focused tests.

## Project generators

Run `mix help` and `mix help <task>`. Search installed Igniter APIs with `mix usage_rules.search_docs "query" -p igniter`. Review every generated diff before keeping it.

| Intended surface | Maintained generator |
| --- | --- |
| Ash domain or resource | `mix ash.gen.domain`, `mix ash.gen.resource` |
| Ash support module | Match the role: `mix ash.gen.change`, `mix ash.gen.validation`, `mix ash.gen.preparation`, `mix ash.gen.enum`, `mix ash.gen.custom_expression`, or `mix ash.gen.base_resource` |
| Web CRUD for an existing Ash resource | `mix ash_phoenix.gen.live` or `mix ash_phoenix.gen.html`; create the domain/resource first |
| Ash migration and snapshot | `mix ash.codegen --dev` while iterating, then `mix ash.codegen <name>` to finalize |
| Import an existing PostgreSQL schema | `mix ash_postgres.gen.resources`; never for an ordinary new resource |
| Deliberate Ecto migration | `mix ecto.gen.migration`; Ash-owned schema uses Ash codegen |
| Deliberate Phoenix/Ecto feature | Matching `mix phx.gen.*`; `context`, `schema`, `live`, `html`, `json`, `embedded` serve deliberate Ecto data; `auth`, `channel`, `socket`, `presence`, `notifier`, `release`, `cert`, `secret` serve only their named infrastructure concern |
| Reusable project transformation | `mix igniter.gen.task`; first prefer a suitable `igniter.refactor.*`, `igniter.add`, `igniter.install`, or `igniter.remove` task |

The dev server may stay live during Ash codegen. Treat every Igniter task as compile-capable; run it sequentially with tests and compiles.

## Generator-First Rule

Create or extend an Igniter generator when any condition holds:

- The change scaffolds from stable inputs: component page, resource, route bundle, test fixture, migration family, or configuration entry.
- One command must create a file and register it in existing Elixir structure.
- The shape exists twice, or another instance is likely.
- Review quality depends on every instance carrying the same structure, metadata, or tests.
- The user asks for consistency, standardization, reproducibility, or future reuse.

Never hand-create what a suitable generator produces. Generate the baseline, then edit only instance-specific content the generator leaves open.

Keep public identity separate from generated function identity. When a page ID maps to the same function name as its production component, require an explicit validated page-function override; never rename public navigation identity or permit a collision.

Treat whitespace-empty tracked destinations as adoptable placeholders when the generator owns the whole file. Upgrade a prior generated scaffold automatically when it carries an explicit stable marker such as `data-ui-placeholder`. Overwrite only those proven generator-owned shapes; reject every other non-empty unregistered destination to preserve user content.

Edit directly only for unique changes without stable input/output contract, or when installed Igniter lacks safe semantic handling. State the reason, keep the change narrow, never disguise raw source rewriting as generator logic.

When real use reveals durable API behavior, a failure mode, or project strategy, return it as a maintenance recommendation. With separate agent-system authority, record trigger guidance here and code patterns in [verified patterns](igniter-patterns.md).

## Tool size

Use an existing task when it owns the whole operation:

- `mix igniter.install package_name`: add dependency and run package installer.
- `mix igniter.upgrade`: update dependencies and run declared upgrade steps.
- `mix igniter.move_files`: align files with module names.
- `mix igniter.refactor.rename_module`: rename module and references.
- `mix igniter.refactor.rename_function`: rename function and references.

Compose existing tasks when the workflow combines supported operations. Write custom AST updates only for project-specific transformations.

## Mutate Elixir Semantically

Open a project module with `Igniter.Project.Module.find_and_update_module!/3`. The updater receives a `Sourceror.Zipper` in the module body.

Use focused navigation and mutation modules:

- `Igniter.Code.Module`: move within module structure.
- `Igniter.Code.Function`: locate and update functions.
- `Igniter.Code.Keyword`: update keyword configuration.
- `Igniter.Code.List`: update literal lists idempotently.
- `Igniter.Code.Map` and `Igniter.Code.Tuple`: update structured literals.
- `Igniter.Code.Common`: traverse and inject quoted code.

Insert Elixir with `quote`, never interpolated source strings. Add unique list entries with `Igniter.Code.List.prepend_new_to_list/3`, which lives in `Igniter.Code.List`, not `Igniter.Code.Module`.

Never assume `open_module` exists; installed Igniter 0.8 updates project source through `Igniter.Project.Module.find_and_update_module!/3`.

## HEEx and EEx

Never parse or rewrite HEEx/EEx with `String.replace/3`.

Use `Igniter.copy_template/5` when the generator owns the whole destination file. The template may hold EEx and HEEx; the copied file is the source of truth.

Never overwrite an existing user-owned template to change one fragment. Lacking a parser-aware semantic API, stop and report the precise limitation. Open an issue only when explicitly authorized. Require a full-file-ownership design before replacing it.

For scaffolding generators that create a file and register metadata, prefer one flat literal registry updated semantically plus one complete generator-owned template. A matching rerun is a no-op; same identity with different metadata is a conflict.

When generated pages repeat named examples, model example metadata as repeatable structured task input: a compact label plus optional source form, duplicates and bounds validated centrally, one compile-time specimen macro that compiles, renders, formats, exposes, and displays that same source. This doctest-like contract keeps captions from drifting into invalid pseudocode. Keep specimen layout and page presentation as validated generator inputs, not repeated wrapper or grid markup.

Expose the generated page registry and accumulated specimen metadata through a documented public introspection function only when an external test or support caller needs it; otherwise keep the seam private. Never use `@doc false`. Generate one generic ExUnit case per registered page that runs the page function and checks the rendered specimen count against registered metadata. Compile-time parsing plus runtime execution then validates examples without one handwritten test per page.

Bound generated specimen source generously enough for real nested slots and form controls; tiny caption-oriented limits defeat executable examples. Keep CLI sources single-line, then let generated heredocs and the HTML formatter set readable layout.

## Fail Explicitly

A missing required module, function, list, or AST shape is a failure. Never guess an insertion point or silently return unchanged.

- Use bang project finders when the module must exist.
- Return a precise issue from the updater for expected source variation.
- Let invariant pattern matches fail during development.
- Never rescue structural failures and continue with guessed source.

Failure protects the repository better than a plausible broken patch.

## Compose Tasks

Use `Igniter.compose_task/4` for sequential Igniter-aware Mix tasks. Declare every composed task in `%Igniter.Mix.Task.Info{composes: [...]}` so option schemas merge. Pass explicit `argv` when the child task needs arguments the parent invocation lacks.

Never shell out to `mix` from an Igniter task when a composable Igniter task exists. Composition preserves one accumulated rewrite and one reviewable diff.

## Structural idempotence

Determine applied state from the AST, not formatted source text.

- Check whether the function, module attribute, keyword entry, or list value exists.
- Add only missing nodes.
- Preserve user ordering unless the operation defines order.
- Run the formatter before final no-op verification.

Never use an empty replacement as an applied marker. Never use replacement text a later rewrite modifies. Never chain string rewrites whose markers invalidate each other.

## Allow String Fallback Only at External Boundary

Never manipulate raw strings for Elixir, HEEx, or EEx. For non-Elixir formats lacking semantic support, stop and ask first. If approved, require an exact unique anchor, an explicit missing/ambiguous-anchor issue, a stable applied marker, and idempotence tests after formatting.

## Verified patterns

Read [verified patterns](igniter-patterns.md) before implementing or reviewing a concrete Igniter task: task skeletons, AST update examples, composition rules, test shapes, and failed patterns from prior refactors.

## Completion Checklist

- Existing task reused where possible.
- Installed API verified.
- AST operation semantic and idempotent.
- Required missing shape fails explicitly.
- Composed tasks declared.
- Complete templates copied only when the generator owns the file.
- Dry-run reviewed before apply.
- Post-format dry-run proposes no changes.
- Focused tests and compilation pass.
