# Failure Modes

Grow this from real friction, never from imagination. One row per observed failure: what happened, the cause, the fix. **Prune a row only after an encoded check or gate prevents recurrence.**

The first entries came from the 48-agent defective-reader panel run on the 16 scaffolded skills, 2026-08-14 — the first real target this skill was worked against.

| Symptom | Cause | Fix |
| --- | --- | --- |
| A skill calls another skill that no longer exists | Renamed or deleted a skill without sweeping incoming references | `.agents/bin/check-harness.sh` link check; sweep `\`skill-name\`` before deleting |
| A reference contradicts the skill that owns it | Moved between skills, never re-read against the new parent | Read every reference end to end against its owning SKILL.md before shipping |
| A "check the budget" step measures something else | Wrote the check from memory instead of running it | Run every command you put in a skill once; paste the real output |
| A step cannot run because its input does not exist yet | Wrote the steady-state workflow, not the bootstrap | Say what the first run does differently on an empty corpus |
| An agent skips a gate by self-classifying around it | Gate depends on a term the same agent defines | Bound the term, or replace the gate with a runnable check |
| A hard constraint disappears for readers who skim | Constraint sat in plain prose below a section's first line | Bold it, or move it up to the first line |
| A cited example path does not exist | Invented an example instead of using a real repo path | Use real paths only — they fail loudly |
| Edits to a skill vanish partway through a session | `git checkout <file>` undid a scratch change by reverting to the *staged* version, discarding every unstaged edit in that file | Undo by re-editing, or `git stash` your own work. Never `git checkout` a file with unstaged work in it. Observed 2026-08-14 while proving the size warning: the padding went, and 33 lines of real work with it |
| Agent treats a runnable check as independent behavioral proof | Confused repeatable execution with a grounded oracle, and could weaken the predicate or accepted baseline beside the artifact | Follow [pressure testing](pressure-testing.md): freeze the evidence and criterion outside the judged output; treat a goalpost edit as new proof and rerun |
| A temporary release-command Machine is described as a reversible migration rehearsal | Confused compute lifecycle with persistent production database side effects, and conflated release commands with Machine checks | Route Fly deployment changes through the owning skill reference; name the release command, Machine checks, health checks, and rollout as separate mechanisms, then prove every live code/schema state |
| Capture creates a card but leaves the proposal board stale | The creation gate named the card path, not the board update | Require `capture-idea` to update `docs/proposals/README.md`; rerun the frozen capture scenario |
| README count or card list diverges from lane folders | Board update had no machine-checked parity rule | Run `.agents/bin/check-proposal-board.rb` after every card creation or move |
| A required reader or pressure agent returns no transcript | Codex service usage limit ended the turn | Record the trial unavailable and the behavioral claim unproven; never call a service failure a clean panel |
| Agent runs the canonical gate manually as a pre-check, post-check, or control around a commit hook | Commit guidance gave the hook ownership only before the commit, so agents renamed the duplicate run | Trace the hook to its alias; run changed-behavior checks before staging, never invoke the hook-owned gate manually around a requested commit, and require its verbose success marker |
| Agent adds a package for one adapter Elixir or project code already covers | Dependency search started at Hex and counted any implementation effort as justification | Record the standard-library, dependency, and project APIs you inspected; add a package only to avoid owning a protocol, parser, security boundary, or continuing compatibility burden |
| A shell search executes Markdown code spans instead of matching them | Backticks sat inside a double-quoted shell argument, so command substitution invoked the named hook | Put literal search patterns containing backticks or `$()` in single quotes; split complex patterns rather than escaping them inside double quotes |
