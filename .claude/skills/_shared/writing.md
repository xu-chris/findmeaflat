# Writing

Someone deciding whether to act reads each artifact once, under time pressure. Skills, references, ADRs, frames, bets, plans, issue comments, PR bodies, commit messages, and chat replies follow this file.

Clear writing is clear thinking. Prose that hides its subject usually hides an unmade decision.

Sources: Lanham, *Revising Prose*; Klinkenborg, *Several Short Sentences About Writing*.

## The paramedic method

Run this on any heavy paragraph.

1. Circle the prepositions.
2. Circle every form of `to be`.
3. Ask who is doing what to whom.
4. Put that action in an active verb.
5. Start fast. Cut the windup.
6. Read it aloud.

Then measure. **Lard factor** = words cut ÷ words started with. A first draft that does not lose a third was already tight or was not revised.

| Before | After |
| --- | --- |
| "The implementation of the verification of the token is performed by the controller" | "The controller verifies the token" |
| "There is a requirement that the actor be checked" | "Check the actor" |
| "It should be noted that skips need justification" | "A skip needs a justification" |

Nominalisations are the usual culprit: `verification`, `implementation`, `utilisation`. Dig the verb out of the noun.

## Sentences

Make them short. A short sentence carries one idea and survives quotation out of context — how agents read.

Each sentence stands alone. Read it in isolation; if it collapses without the one before it, it was leaning.

Vary the length. Uniform short sentences read as a list; uniform long ones read as fog.

Transitions are not glue. `However`, `Moreover`, `Furthermore`, `That said` mark a connection the sentences should already make. Cut them and check whether anything broke.

Trust the reader. Say the thing once.

## Banned forms

| Form | Looks like | Instead |
| --- | --- | --- |
| **Cliffhanger** | "The reason will matter later." "More on this below." | Say it here, or delete it. |
| **Information gap** | "There is one thing that will waste your time." | Name the thing in the same sentence. |
| **Time trick** | "Before we get to the gate…" "We will return to this." | Order the content by when it is needed. |
| **Correlative conjunction** | "not only X but also Y", "either X or Y", "both X and Y" | Two sentences, or a list. |
| **Action-oriented heading** | `## Freeze the artifact`, `## Cut scope` | A noun label: `## Artifact freeze`, `## Scope` |
| **Introductory clause** | "Before editing code, read the references." | "Read the references before editing code." |
| **Half-empty clause** | an em dash or colon joining a windup to the real content: "Mixing these up is the common failure: …", "only headings — never a full paragraph" | Cut the half that carries nothing. Usually the first. |
| **Amplification** | "genuinely", "actually", "really", "very", "simply", "just", "of course", "obviously", "clearly", "exactly", "the whole point is", "it is worth noting" | Delete. The claim carries its own weight or it does not. |

Amplifiers fail most often: they signal that the writer doubts the sentence. A rule needing "genuinely" in front is stated too weakly.

## Headings

A heading names its contents — a label, not an instruction.

`## Effort`, not `## Select the effort level`. `## Rabbit holes`, not `## Patch every rabbit hole`. The imperative belongs in the body, where it states a rule rather than a signpost.

Skill `name` fields stay verb-first. The frontmatter spec requires that; it does not extend to headings inside the file.

## Checking

`.claude/skills/craft-skills/scripts/check-prose.sh` flags every form above plus hedges and nominalisations. It reports; it never rewrites.

```bash
.claude/skills/craft-skills/scripts/check-prose.sh --summary        # counts per rule
.claude/skills/craft-skills/scripts/check-prose.sh docs/ | jq .     # JSON: rule, file, line, match, text
.claude/skills/craft-skills/scripts/check-prose.sh path/to/file.md  # one file
```

JSON is the default output, so every finding is a `file:line` you can open. It skips code fences, blockquotes, inline code, and double-quoted text — source quotations keep the prose they came with.

A flagged line is a candidate, not a verdict. A rule about one of these words, and a count where the number carries meaning, are both false positives.

Read the result aloud before accepting it. The ear catches what the regex cannot.
