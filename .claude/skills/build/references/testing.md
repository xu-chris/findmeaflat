# Testing and Verification

**FindMeAFlat deltas only.** No `docs/craft/testing.md` exists yet, so there are no `TST-00n` ids to cite — treat this file as the rules. hexdocs `ExUnit.Case` and `Phoenix.LiveViewTest` own general behaviour.

**The load-bearing test in this project is the portal fixture test:** stored HTML per portal, asserting at least N listings parse with non-nil id, title and url. Five portals broke silently for months because nothing asserted this.

Project-specific reference; inherit authority and scope from the calling skill.

Worked good/bad pairs for the seam, tautology, side-channel and doubling rules: [test-examples.md](test-examples.md).

Load for tests and for format, compile, documentation, migration, and focused verification commands. Keep command boundaries attributable; avoid shared-state races.

## Rules

- **FunWithFlags isolation:** Apply TST-008. Keep `async: false` when `on_exit` cleanup touches database state; it runs outside test-process Sandbox ownership.
- **Testing authority:** Apply TST-001, TST-002, TST-006, TST-009 to changed tests and new nearby proof. That guide owns boundary, setup, duplication, verification. Never start suite cleanup.
- **Collision control:** Unique fixture values (`"test-#{System.unique_integer([:positive])}@example.com"`) when a field carries a uniqueness or identity constraint, or concurrent tests share a visible namespace. Uniqueness does not replace TST-008 isolation.
- LiveView tests use `Phoenix.LiveViewTest` plus `LazyHTML`, targeting template IDs, never raw text. A tag-input submit uses only values already rendered as hidden tag controls; add a new tag through its client interaction first.
- Pure agent-compiler tests need job bindings, not `Auth.system_scope/0`; omitting scope avoids Sandbox ownership.
- Assert stored plan entries against normalized action output; input entries gain defaults such as empty `notes`.
- Run `render(lv)` before component assertions following an async `send_update/3`; a queued `:send_update` flakes CI.
- Credence `no_repeated_enum_traversal` / `no_nested_enum_on_same_enumerable` track variable names module-wide; never reuse a traversed `results`. Assert `IndustryEvents.foo!(...) |> Enum.map(& &1.id)`, then `assert id in ids`; `in` uses `Kernel.in`.
- Run plain `mix test`; Mix picks the environment, so never prefix `MIX_ENV=test`. `mix test` and `mix compile` may run while the app server lives. Run compile-capable commands sequentially; concurrent compilers block or redefine modules.
- Never start a second dev server for route validation; startup can execute Oban cron jobs. Use route introspection and isolated LiveView tests.
- Never join independent verification commands with shell operators; each needs its own result and failure boundary.
- Run formatting and compilation separately so failures stay attributable.
- Composite identity errors: never infer Ash's field assignment; test invariant failure unless the mapping is public behavior.
- **Test placement:** Separate test when the claim differs, the setup path is itself the contract, or each boundary rejects a different wrong implementation. Otherwise extend the existing one.
- Bind a struct field to a local before pinning it as a map key; remote calls are invalid match keys.
- Line-targeted test: verify its current `test/...` path and line number, after formatting too; resource paths need not mirror tests, and edits shift lines. Recompute DOM indices after collapsing transcript items; surviving messages shift.
- **Helper output:** Expand a shared helper only after a second, independently required consumer uses the same inputs and result contract (TST-006). Never add a consumer to justify extraction. Return every value a new test destructures.
- Never mutate the persistent test database with `MIX_ENV=test mix eval`; use sandboxed ExUnit tests, or clean exact diagnostic records immediately.
- Earlier-migration test against the latest schema: create the legacy table in a non-async sandbox transaction when a later removal migration exists.
- `Spark.Test` helpers capture Spark verifier failures; compilation does not raise them.
- Match typed DSL structs by fields, never against plain maps.
- Never run `mix compile --warnings-as-errors` beside `mix test`; concurrent compilers redefine loaded modules and fail on warnings unrelated to the change.
- `[]` is truthy in Elixir; assert empty issue lists with `== []`, not `refute`.
- Inspect generated DSL exports with `module.__info__(:functions)` or the public compiler API before runtime assertions; never guess callback names.
- Match prose across wrapped heredoc lines with whitespace-tolerant regexes; exact substrings break at formatter line breaks, prompt-strategy tests included. Cover the observed break and every likely wrap boundary. Recheck adjacent assertions after prompt text moves. Normalize whitespace once when one test checks several phrases.
- Normalize rendered component whitespace or assert semantic fragments; HEEx formatting inserts valid newlines around slot content.
- HTML formatter failures raise `Phoenix.LiveView.TagEngine.Tokenizer.ParseError`; verify exception namespaces before asserting.
- Search tests for the exact old phrases before rewriting DSL text. Verify in the owning field: strategy rules in `Definition.strategy`, action `when_to_use` text in compiled tool descriptions.
- Assert generated HEEx source literals before HTML rendering; generator output is not browser-escaped.
- In Ruby regex literals, write Markdown heading cardinality `(?:#|##)`; `#{1,2}` starts interpolation.
- Where one public arity delegates to another, verify delegated values satisfy the callee contract; never inherit checks specific to one caller path, and test each path separately.
- Test each Ash code-interface not-found result against its verified public contract. Never assume `Ash.Error.Invalid`; interfaces return a record, `nil`, or an ok/error tuple depending on declared action and interface.
- `MIX_ENV=test mix ecto.reset` runs seeds; keep `priv/repo/seeds.exs` a no-op in test so reset databases stay deterministic.
- Reload dynamic fixture values through their context before calling typed functions.
- LiveViewTest does not expose content `Portal` teleports out of the owning view fragment. Test server events directly; verify portaled menu/dialog DOM through Tidewave browser interaction. Tidewave locators can outlive a focus-sensitive menu — inspect or activate portaled rows immediately after opening. To activate, click trigger and row with sequential `browser.click` calls in one evaluation; synthetic dispatched clicks reach LiveView inconsistently.
- Reuse verified Work fixture attributes in runtime probes; `production_country_codes` requires at least one code.
