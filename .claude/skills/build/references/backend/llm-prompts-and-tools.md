# LLM Prompts and Tools

**FindMeAFlat deltas only.** `deps/req_llm/usage-rules.md` and hexdocs `ReqLLM`, `ReqLLM.Tool`, `ReqLLM.Context` own general behaviour.

Project reference only; inherit authority and scope from the calling skill.

Load when approved implementation changes an `ash_ai` prompt-backed action, an MCP tool definition, or a vectorisation strategy. **Nothing LLM-backed exists yet** — `ash_ai` is a roadmap item, not an installed dependency.

## Altitude and structure

Start minimal. Avoid brittle condition catalogs and context-free vagueness; add an instruction only after an observed failure. Order sections Role, Context/Facts, Instructions/Workflow, Output format, Rules/Constraints. Separate them with XML tags such as `<context>` and `<instructions>`, or with Markdown headings.

## Examples

Use a few diverse canonical examples, not an edge-case catalog. Show good and bad outputs, explain the difference, and teach format, tone, and decision boundary together.

## Subagents and delegation

For `system_prompt()`, assign a role, number the workflow, supply required facts, specify key-value, Markdown, or JSON output, demand explicit gaps and unverified data, forbid fabrication, and state the iteration limit and stop condition.

For `usage_rules()`, define exact delegation triggers, no-delegation cases, returned format, and concrete good/bad examples.

## Tools and context

Keep tools minimal, non-overlapping, self-contained, error-safe, and described in one sentence. Return token-tight results. Rename or split any tool a human finds ambiguous.

Pass lightweight paths, queries, or URLs, not preloaded data. Retrieve just in time and feed one agent output into the next operation.
