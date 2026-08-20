# Elixir and Ash Implementation

**FindMeAFlat deltas only.** General Ash, Spark, and ReqLLM behaviour lives in `deps/ash/usage-rules.md`, `deps/ash/usage-rules/*`, `deps/ash_postgres`, `deps/ash_phoenix`, `deps/ash_oban`, `deps/spark`, `deps/req_llm`, and hexdocs `Ash.Resource.Dsl` / `Ash.Policy.Authorizer` / `AshPostgres.DataLayer`. Read those for how a thing works; this for what bit us.

Project-specific reference; inherit authority and scope from the calling skill.

Load for Elixir, Ash, Spark, Boundary, ReqLLM, telemetry, and DSL work. Version-matched usage rules and hard standards stay authoritative.

## Existing authorities

- `docs/craft/architecture.md` ARC-005 governs O100; never duplicate its prose.
- `docs/craft/ash.md` generated-migration review guidance governs O176; never duplicate its prose.
- `docs/craft/elixir.md` ELX-007 governs O240; never duplicate its prose.

## Project API conventions

- Document only with `@doc`, `@moduledoc`, or `attr doc:`. Never list fields or functions.
- `@doc` on every public function and macro: purpose, when callers use it, short first paragraph, functions as `name/arity`.
- Never `@doc false`. Document a public API's purpose and call site; make internal functions private.
- Private-function notes go one line above `defp`, never inside the body.
- Ash resources carry the data layer; reach for a bare Ecto schema only where Ash genuinely does not fit, and say why.

## Rules

- Ash `:string` trims outer whitespace; set `constraints trim?: false` when exact text must survive.
- AshPostgres `check_constraint` takes the affected resource attribute first; the database constraint name goes in `name:`.
- Default arguments cannot reference an earlier argument; use an arity wrapper.
- Never give an owner and its referenced helper separate top-level Boundaries; keep helper logic inside the owner.
- Never wrap a Boundary-declared Mix task module in `Code.ensure_loaded?/1`; conditional definition escapes Boundary analysis.
- Spark DSL entities stay inside their defining module; top-level module attributes cannot compile.
- PostgreSQL `ORDER BY` output aliases work only as bare names; for casts or expressions, repeat the source expression or wrap the select in a subquery.
- Verify every Ash code-interface input and return shape before calling or matching; `get_by` forms yield `record | nil` or ok/error tuples, and composite gets may return tuples.
- Never delete generated Ash resource snapshots before verifying AshPostgres snapshot semantics; snapshots are historical migration state.
- Give every Ecto migration unique file + module names. Rename same-slice follow-ups before verification.
- Never persist full `ReqLLM.Response` / `ReqLLM.Context`; `ReqLLM.Tool` structs are non-JSON. Persist `ReqLLM.Context.to_list/1` + explicit response metadata.
- ReqLLM request telemetry nests token counts under `usage.tokens`, cost fields stay on `usage`; normalize both layers before accumulating.
- Pass range or request context explicitly through stream reductions; never hide it in the process dictionary.
- Keep retry and force-start separate: retry creates a fresh terminal-job copy; force start claims and executes the existing queued row.
- Telemetry callbacks are external fail-safe boundaries: handle malformed metadata and rescue every exception after logging, or `:telemetry` detaches them.
- Avoid ambiguous one-line `do: if`; use a multi-line `if`, or parenthesize `do: if(...)` when formatting collapses a short function. Never swap boolean `if` for `case true/false`; Credence rejects it.
- `String.valid?/1` is not guard-safe; dispatch inside a binary clause.
- Converting Ash types for a JSON tool schema: map every built-in storage atom before resolving custom Ash type modules.
- Inspect resource-wide update changes before adding an update action. Scope non-atomic changes away from it or set `require_atomic? false`; action-specific `accept []` does not stop global update changes. Even simple atomic updates need a primary read action or a configured `atomic_upgrade_with` action.
- Transcript message content may be structured parts, not a string; normalize before string functions.
- `Credo.Execution.checks/1` returns `{selected, only_matching, ignored}`; destructure all three before enumerating configured checks.
- A lookup map with several representations per DSL parameter takes separate key-value pairs, not a tuple key.
- Never define a public and a private function with the same name/arity in one module; Elixir sees a duplicate definition.
- Keep a function's clauses contiguous; a helper inserted between them warns at compile.
- ReqLLM structs may enforce keys and define partial custom Inspect clauses; inspect empty shapes with `Map.from_struct(Module.__struct__())`.
- Set `destination_attribute` explicitly when a `has_many` name differs from its inverse `belongs_to`.
- Never enable Ash pre-checks on partial identities; pre-check queries omit identity `where` filters and reject historical rows.
- Call `Code.ensure_loaded?/1` before `function_exported?/3` in runtime checks and optional callback resolution; lazy modules otherwise look unavailable. Looping over union-typed modules, invoke confirmed callbacks with `apply/3` so static analysis does not warn about callbacks other union members lack.
- `ash_ai` tools can only filter or sort on `public?: true` attributes; private ones need an explicit `load`. Attribute visibility is an API design decision, not just an internal one.
- Use an explicit `try/rescue` boundary or structural match; never inline `rescue` inside an expression.
- Removing an Ash action also removes its PubSub declarations and exclusion-list references.
- Ecto migration DDL is queued; wrap data reads or writes depending on prior DDL in `execute/1` so they run after the schema command.
- Create composite unique indexes on referenced tables before foreign keys that use `with:`; PostgreSQL validates the referenced key during table creation.
- Ecto `IN (subquery)` requires an explicit single-field `select`; reuse a separate ID query instead of a full-resource deletion query.
- Migrations do not resolve nested Ecto schemas by bare name from the outer module; alias full module paths before building queries.
- Spark standalone DSL, grouped syntax: a top-level root section + nested groups. A top-level group flattens content and creates no block macro.
- `use Module` invokes `Module.__using__/1` as a macro with options, `[]` included; DSL `__using__` macros need arity one, and runtime introspection must expand quoted `use` rather than call `Module.__using__/1` as a function.
- Keep Spark extension sections self-contained inside the extension module; top-level temporary values are invalid Elixir and destabilize compile ordering.
- Ecto query bindings are scoped to query macros; calculated updates referencing a binding need `update([binding], ...)` before `Repo.update_all/2`.
- Never name a local variable `after`; reserved syntax.
- Avoid module attributes named after top-level Spark sections in new DSL extensions; this project's Styler moves them outside the module.
- Add `# quokka:skip-module-directives` to Spark extension modules before formatting.
- Normalize human-readable LLM action names with string replacement; `Macro.underscore/1` only handles module-style names.
- Keep model tiers/corridors and provider fallbacks in runtime configuration: user-facing APIs pass execution scope, model policy maps scope to a named corridor, agent DSL choices stay limited to agent tiers.
- Resolve Ash-backed LLM tools through domain code interfaces and non-bang calls; never emulate normal flow by rescuing bang calls.
- Check pipe argument order against helper signatures before compiling a new reducer.
- `ReqLLM.Billing.calculate/2` expects usage before model; verify argument order in cost probes.
- ReqLLM inline pricing components require string `kind` values such as `"token"`, not atoms.
- Never place a catch-all private helper clause before its internal variant; use distinct helper names.
- Ash read actions do not expose `:accept`; use `Map.get(action, :accept, [])` when deriving tool inputs.
- Normalize a get-by `:id` to a resource-specific tool parameter such as `edition_id`; keep Ash's internal key in the adapter.
- Bind a matched struct to a variable before reading metadata the function head skips.
- Compile agent middleware only when one of its declared actions is selected; strategy alone grants no tools.
- Keep every DSL option the compiler consumes in its immutable definition struct.
- `quote bind_quoted:` locals do not cross generated `def` boundaries; unquote compile-time constants into function bodies or store them in module attributes.
- Ash update and destroy interfaces requiring a record expose a fixed `record_id` and fetch with non-bang `Ash.get/3`; never synthesize resource-specific atoms.
- Validate action-binding targets against the generated tool schema before Loop assembly.
- Use Ecto queries for migration data changes; raw SQL is reserved for schema operations Ecto cannot express.
- New Mix task modules must declare `use Boundary, top_level?: true, deps: [...]`; otherwise boundary compilation warns.
- A scaffold helper introduced before its first generated consumer must be public or consumed in the same compile; unused private helpers warn.
- Nested `Ecto.Schema` modules inside migrations must declare timestamp fields explicitly, else the imported `timestamps/0` macro conflicts.
- Migration `insert_all` joins need local typed Ecto schemas; raw table names do not dump UUID strings for PostgreSQL.
- Composite foreign keys using `:nilify` null every FK column; use `{:nilify, [:foreign_key]}` to retain mandatory shared keys.
- Give a local alias a distinct `as:` name before referencing namespace children when it shares a top-level namespace used in the same module.
- Merging an embedded Ash resource takes only declared attributes; `Map.from_struct/1` carries Ash metadata that embedded update actions reject.
- In Elixir load lists, bare atoms come before keyword association entries; keyword entries last.
- Adding metadata to a helper result: construct the helper with its declared identifier argument before piping into `Map.put/3`.
- Never normalize provider endpoint URLs; use runtime configuration exactly as supplied.
- Named Ash actions on resources with `default_accept` must set `accept []` when only action arguments should be writable; otherwise unrelated attributes leak into derived tools.
- Keep non-atomic Ash validations on affected actions; resource-wide function validations disable unrelated atomic updates.
- `nil` is an atom in Elixir; never combine `is_atom(value)` with `is_nil(value)` when validating atom-or-nil input.
- `:code.all_available/0` may return module names as charlists; normalize before calling atom-only functions.
- `Repo.delete_all/2` requires an `Ecto.Query`; it takes no `where:` option.
- Normalize local action parameter types through `ToolBuilder.tool_type/1` before constructing ReqLLM schemas.
- Import `JobReference` in every DSL section accepting `with: [field: job(:field)]` bindings.
- Keep framework introspection out of guards; evaluate in function bodies.
- Use a normal string for one-line module docs; heredocs need a newline after the opening delimiter.
- Ash DSL directives require direct invocation: write `description "..."`, never a bare directive name with its value on the next line.
- Verify TOON protocol support before relying on default Ash-tool feedback; Work structs are unencodable and hold credential fields needing a narrow projection.
