#!/usr/bin/env bash
# Flags prose forms this project does not use. Reports candidates; never rewrites.
# Rules: .claude/skills/_shared/writing.md
#
#   check-prose.sh [path ...]              JSON findings on stdout
#   check-prose.sh --summary [path ...]    counts per rule
#
# JSON shape:
#   {"total":N,"counts":{"amplification":N,...},
#    "findings":[{"rule":"amplification","file":"...","line":12,"match":"genuinely","text":"..."}]}
#
# Every finding is a candidate, not a verdict. Quoted source text, rules about
# the words themselves, and counts where the number is load-bearing ("exactly
# one of") are false positives. Read the line before changing it.
set -uo pipefail
cd "$(dirname "$0")/../../../.." || exit 1

mode=json
if [ "${1:-}" = "--summary" ]; then mode=summary; shift; fi

targets=("$@")
if [ ${#targets[@]} -eq 0 ]; then
  targets=(.claude/skills AGENTS.md docs/threat-model.md docs/agents docs/business .agents/README.md)
fi

python3 - "$mode" "${targets[@]}" <<'PY'
import json, os, re, sys

mode, targets = sys.argv[1], sys.argv[2:]
SKIP = ("create-product-mail/references/", "backend/dependencies.md", "_shared/writing.md",
        "craft-skills/scripts/")

RULES = {
 "amplification": r"\b(genuinely|actually|really|very|simply|obviously|clearly|absolutely|truly|literally|needless to say)\b|\bof course\b|\bit is worth noting\b|\bthe whole point (is|of)\b",
 "correlative conjunction": r"not only\b[^.]{0,60}\bbut also\b|\bnot only\b|\beither\b [^.]{0,40}\bor\b|\bneither\b [^.]{0,40}\bnor\b",
 "hedge": r"\b(perhaps|somewhat|fairly|arguably|it seems|kind of|sort of)\b",
 "information gap": r"(will (become clear|make sense) (later|below)|more on (this|that) below|as we.{0,5}ll see|we (will|shall) return to|for now,)",
 "action-oriented heading": r"^#{2,6} (Freeze|Cut|Patch|Build|Write|Run|Read|Load|Select|Verify|Check|Report|Ship|Resolve|Stage|Push|Add|Use|Keep|Make|Log|Name|Skip|Apply|Choose|Compare|Wire|Rank|Post|Send|Find|Fix|Pick|Handle|Decide|Define|Avoid|Prefer|Start|Never|Always)\b",
 "introductory clause": r"^(Before|After|Afterwards|Once|Having|Prior to|In order to|Rather than|Instead of|Because)[^.!?]{5,70},",
 "nominalisation": r"\bthe (verification|implementation|utilisation|utilization|application|creation|determination|configuration|specification) of\b|\bis performed by\b|\bis carried out by\b",
}
COMPILED = {k: re.compile(v, re.I) for k, v in RULES.items()}

files = []
for t in targets:
    if os.path.isfile(t) and t.endswith(".md"):
        files.append(t)
    else:
        for root, _, names in os.walk(t):
            files += [os.path.join(root, n) for n in names if n.endswith(".md")]
files = sorted(f for f in files if not any(s in f for s in SKIP))

findings, fence = [], False
for f in files:
    fence = False
    try: lines = open(f, encoding="utf-8").read().split("\n")
    except OSError: continue
    for i, line in enumerate(lines, 1):
        if line.lstrip().startswith("```"): fence = not fence; continue
        if fence or line.lstrip().startswith(">"): continue   # code and quoted source
        probe = re.sub(r'"[^"]*"', '""', line)                   # quoted source is not our prose
        probe = re.sub(r'`[^`]*`', '``', probe)                  # nor is inline code
        for rule, rx in COMPILED.items():
            m = rx.search(probe)
            if m:
                findings.append({"rule": rule, "file": f, "line": i,
                                 "match": m.group(0).strip(),
                                 "text": line.strip()[:200]})

counts = {}
for x in findings: counts[x["rule"]] = counts.get(x["rule"], 0) + 1

if mode == "summary":
    print("== prose check ==")
    for r in RULES:
        print(f"  {r:<26} {counts.get(r, 0):>4}")
    print("  " + "-" * 3)
    print(f"  {'candidates':<26} {len(findings):>4}   ({len(files)} files)")
    print("\n  Candidates, not verdicts. JSON with file:line — run without --summary.")
else:
    print(json.dumps({"total": len(findings), "files_scanned": len(files),
                      "counts": counts, "findings": findings}, indent=2))
PY
