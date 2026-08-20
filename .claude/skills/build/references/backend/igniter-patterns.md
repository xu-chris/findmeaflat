# Verified Igniter Patterns

These patterns target Igniter 0.8.x. **Igniter is not installed in this repository yet** — there is no Elixir project. Verify every signature against the installed version once `mix igniter.new` has been run.

## Contents

1. Task skeleton
2. Module AST update
3. Idempotent list update
4. Task composition
5. Complete template generation
6. Project scaffolding generator
7. Test matrix
8. Failure rules
9. Anti-patterns

## Task Skeleton

Generate skeleton first:

```sh
mix igniter.gen.task my_app.refactor.example --dry-run
mix igniter.gen.task my_app.refactor.example --yes
```

Keep task declarative:

```elixir
defmodule Mix.Tasks.MyApp.Refactor.Example do
  @shortdoc "Applies one deterministic refactor"
  @moduledoc """
  Applies one deterministic refactor through Igniter.

      mix my_app.refactor.example --dry-run
  """

  use Igniter.Mix.Task

  @doc "Describes task options and composed tasks to Igniter."
  @impl Igniter.Mix.Task
  def info(_argv, _parent) do
    %Igniter.Mix.Task.Info{
      group: :my_app,
      composes: ["other.task"],
      example: "mix my_app.refactor.example --dry-run"
    }
  end

  @doc "Builds proposed project rewrite without writing files directly."
  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> Igniter.compose_task("other.task")
    |> update_target_module()
  end

  # Adds project-specific AST change to accumulated rewrite.
  defp update_target_module(igniter) do
    Igniter.Project.Module.find_and_update_module!(igniter, MyApp.Target, fn zipper ->
      update_target_ast(zipper)
    end)
  end

  # Returns changed zipper or precise structural failure.
  defp update_target_ast(zipper) do
    # Semantic navigation and mutation here.
    {:ok, zipper}
  end
end
```

Never write files from the callback. Return accumulated `%Igniter{}`.

Under Boundary-enforced Mix tasks, define the task module unconditionally with its required `use Boundary`. Igniter's optional `if Code.ensure_loaded?(Igniter)` scaffold hides it from Boundary analysis; drop that wrapper when the project already treats Igniter as task-time dependency.

Keep task source formatter-stable. If the formatter lifts a shared Mix-task example attribute into top-level temporary code, duplicate the stable example literal in docs and `info/2`.

## Module AST Update

`Igniter.Project.Module.find_and_update_module!/3` finds project file, moves zipper into module body, applies updater.

Add declaration only when absent:

```elixir
Igniter.Project.Module.find_and_update_module!(igniter, MyApp.Target, fn zipper ->
  case Igniter.Code.Function.move_to_def(zipper, :generated_capability, 0) do
    {:ok, _definition} ->
      {:ok, zipper}

    :error ->
      code =
        quote do
          @doc "Returns capability installed by project refactor."
          def generated_capability, do: :ok
        end

      {:ok, Igniter.Code.Common.add_code(zipper, code)}
  end
end)
```

Important:

- Match semantic identity: function name plus arity, module name, attribute name, or data value.
- Keep module-body zipper when checking for existing definition; found zipper points elsewhere.
- Add quoted AST. Never build `def` as string.
- To change an existing definition, continue from found zipper; never add a duplicate.

Navigation:

- `Igniter.Code.Module.move_to_defmodule/1,2`
- `Igniter.Code.Module.move_to_use/2`
- `Igniter.Code.Function.move_to_def/3`
- `Igniter.Code.Function.move_to_defp/3`
- `Igniter.Code.Module.move_to_attribute_definition/2`

`Igniter.Project.Module` owns project-level module file discovery. Some older `Igniter.Code.Module` project helpers are deprecated.

## Idempotent List Update

Navigate to the literal list zipper, then use:

```elixir
Igniter.Code.List.prepend_new_to_list(
  list_zipper,
  quote(do: MyApp.Extension)
)
```

Returns `{:ok, zipper}` or `:error`. Default equality compares AST nodes semantically; pass a custom equality callback only when that misses identity.

For keyword-held list, reach or create the key with `Igniter.Code.Keyword`, then apply the list operation. Never stringify a keyword list and append text.

## Task Composition

Compose supported workflows inside one rewrite:

```elixir
def info(_argv, _parent) do
  %Igniter.Mix.Task.Info{
    composes: ["igniter.install", "igniter.refactor.rename_module"]
  }
end

def igniter(igniter) do
  igniter
  |> Igniter.compose_task("igniter.install", ["some_package"])
  |> Igniter.compose_task(
    "igniter.refactor.rename_module",
    ["MyApp.Old", "MyApp.New"]
  )
end
```

Rules:

- Declare child task names in `composes`.
- Pass explicit child argv when needed.
- Let child task update same `%Igniter{}`.
- Missing task without fallback becomes an issue, never a silent skip.
- Never invoke `System.cmd("mix", ...)` for composable task.

## Complete Template Generation

Use complete template for generator-owned file:

```elixir
Igniter.copy_template(
  igniter,
  "priv/templates/example.html.heex.eex",
  "lib/my_app_web/components/example.html.heex",
  [module: MyAppWeb.Example],
  on_exists: :error
)
```

`copy_template/5` evaluates source through EEx, creates destination through Igniter. Review `on_exists` behavior explicitly.

Use this for new, fully-owned EEx or HEEx files. Never substitute full-file template copy for semantic edit of existing user-owned file.

## Project Scaffolding Generator

Use one generator for workflows that create a file and register it in project code:

1. Validate stable CLI inputs: kebab-case page ID, snake-case production component, title, group, description. Never derive component invocation from pluralized page ID.
2. Keep registration metadata in one flat literal list.
3. Enter target module with `Igniter.Project.Module.find_and_update_module/3`.
4. Igniter project-module updater callbacks start inside the module body; search that zipper directly, do not re-enter `defmodule`.
5. Navigate to literal list, call `Igniter.Code.Common.maybe_move_to_single_child_block/1`, then `Igniter.Code.List.append_new_to_list/3`.
6. Sourceror wraps parsed literals in `:__block__`. Use `Igniter.Code.Common.expand_literal/1` before comparing runtime identity or metadata.
7. Copy complete destination with `Igniter.copy_template/5`.
8. On rerun, matching registry identity and metadata plus existing file is no-op. Same identity with different metadata is precise issue.
9. Test missing module, missing registry, initial generation, metadata conflict, post-format rerun.

Keep generated template capsule-safe and convention-bearing. Scaffold semantic structure and project-owned classes, not ad hoc utility combinations. Generated placeholder names what instance-specific production markup remains.

For component-library generators, prefer a doctest-like compile-time specimen macro:

1. Accept one literal HEEx source per named scenario plus validated row/stack layout.
2. Format source with `Phoenix.LiveView.HTMLFormatter.format/2`.
3. Compile that same source with `Phoenix.LiveView.TagEngine.compile/2`.
4. Render compiled source, display/copy formatted source; never keep separate pseudocode caption.
5. Register source metadata on an accumulating caller attribute so one generic test audits every specimen.
6. Let invalid tags, component names, attributes, values, and HEEx syntax fail owning page compilation.
7. Expose page registry and specimen metadata through documented public introspection only when a real external test or support caller needs it; otherwise keep the seam private. Never use `@doc false`. Generate one ExUnit test per registered page, execute its embedded-template function, assert rendered code-block count equals metadata count.

Generated examples then work as executable documentation: source parses at compile time, every registered page executes during tests. Generator tests still verify emitted macro syntax, layout validation, safe placeholder upgrades, idempotent registration, post-format no-op behavior.

Give each generated debug page a deterministic DOM ID and data attribute derived from validated page identity. Stable targets keep screenshot and interaction checks independent of item order and remove manual selector scaffolding.

## Test Matrix

Use `Igniter.Test.test_project/1` with small fixture source. Compose task, inspect rewrite, cover these cases:

1. Required module and target shape exist: expected patch produced.
2. Required module missing: task reports precise issue or fails.
3. Required inner shape missing or ambiguous: task reports precise issue or fails.
4. Desired code already exists: no content change.
5. Apply change, format result, rerun task: no content change.
6. Composed task arguments and option schemas propagate.

Representative shape:

```elixir
test "adds declaration once" do
  igniter =
    Igniter.Test.test_project(
      files: %{
        "lib/my_app/target.ex" => """
        defmodule MyApp.Target do
        end
        """
      }
    )
    |> Igniter.compose_task("my_app.refactor.example")

  assert Igniter.changed?(igniter)

  rerun =
    igniter
    |> Igniter.Test.apply_igniter!()
    |> Igniter.compose_task("my_app.refactor.example")

  refute Igniter.changed?(rerun)
end
```

Confirm test helpers against installed Igniter before copying this shape; helper APIs move between versions.

## Edge Cases Carried Over From Another Project

These were observed elsewhere and are unverified here. Re-confirm before relying on any of them.

- Format each changed Igniter task before dry-run so malformed rewrite sigils fail before transformation.
- Never put apostrophes inside `~S'...'` Igniter source literals; they terminate sigil. Reword or use another delimiter.
- Count matching `do`/`end` tokens inside Igniter replacement source. Dry-run parser failure means the virtual edit is invalid.
- Validate every Sourceror zipper navigation result before reading its node.
- Run `mix help task.name` before invoking a presumed Igniter task; installed task names vary by version.
- A formatter-sensitive `replace_exact` fallback needs a target-unique semantic applied marker. Never fall back to generic replacement detection; repeated fragments skip required work.
- Order composed rewrites after every producer of their expected intermediate form, guide and test rewrites included. On rerun, upstream steps must recognize downstream final output as satisfied.
- Re-read formatted sigil heredocs before exact matching. Indentation beyond the closer stays content.
- Test Igniter idempotence against formatter-normalized target text; pre-format heredoc indentation is not a stable applied marker.
- Never nest an unescaped triple-quote heredoc inside another heredoc; use a different sigil delimiter for generated source.
- Use a verified heredoc delimiter such as `~S'''` when embedded content contains `"""`; arbitrary sigil delimiters and same-line heredoc closers are invalid.
- Anchor Igniter-script patches outside quoted replacement source; an internal `end` silently nests helpers inside a sigil.
- Use unpaired quote sigils for incomplete Igniter source fragments; paired delimiters require balanced lexical forms such as matching `do`/`end`.
- Remove AST list entries with `Igniter.Code.List.remove_from_list/2`; removing only an atom zipper leaves `nil` in the list.
- Sourceror wraps literals in `:__block__`. Use `Common.nodes_equal?/2` for exact AST, `Common.expand_literal/1` for runtime values, `Macro.to_string/1` only for intentional substring matching.
- `Igniter.Test.assert_has_patch/3` expects Igniter diff lines containing `|`; use `Igniter.Test.diff/2` for plain substring assertions.
- Batch related renames in one custom task. `igniter.refactor.rename_module` takes one pair and may compile on every invocation.
- Source-only `mix run --no-start` tasks start Rewrite supervision with `Application.ensure_all_started(:igniter)`.
- After rename, search exact old module, lexical-prefix siblings (`Tool` may rewrite `ToolBuilder`), stale alias locals, last-segment alias collisions, `apply/3`, `Module.concat/2`, configuration, persisted module names. Resolve collisions with namespace-qualified modules, never `as:` compatibility aliases.
- Guard `Igniter.rm` with a file-existence check so private refactors stay idempotent after deletion.

## Failure Rules

Choose failure by ownership:

| Situation | Result |
| --- | --- |
| Task invariant violated | Pattern match or bang finder failure |
| User source has supported variation | Handle the alternative AST shape |
| User source shape unsupported | Precise issue, then stop |
| Semantic target appears twice | Ambiguity issue, then stop |
| Desired node already exists | Unchanged zipper |
| Optional target absent by design | Documented no-op, plus a test |

Never convert every `:error` to unchanged source. That hides drift and makes the task look successful.

## Anti-Patterns

| Do not | Why it failed | Use instead |
| --- | --- | --- |
| `String.replace(source, old, new)` on Elixir | Formatter changes indentation and line wrapping | Semantic zipper navigation plus quoted AST |
| Replacement text as applied marker | Later rewrite or formatter changes the marker | Inspect AST for the desired node |
| Empty string as applied marker | Empty string always matches | Semantic presence check |
| Multiple chained source rewrites | Early rewrite invalidates later anchors | One structural traversal or composed transformations |
| Match broad structural suffix | Inserted code matches the suffix on rerun | Match semantic identity |
| Rescue updater failure and inject at module end | Broken target becomes a plausible broken patch | Precise issue or failure |
| Guess `open_module` from old example | API absent in installed Igniter | Verify docs; use `Igniter.Project.Module.find_and_update_module!/3` |
| Attribute `prepend_new_to_list` to module API | Function lives elsewhere | `Igniter.Code.List.prepend_new_to_list/3` |
| Overwrite existing HEEx for fragment edit | Destroys user changes | Parser-aware edit, or stop for a design decision |
| Apply before inspecting | A large deterministic mistake is still deterministic | Dry-run, inspect, apply, rerun no-op |
