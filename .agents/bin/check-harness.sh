#!/usr/bin/env bash
# Static consistency check for the skill harness. No router topology, no oracle —
# just the four things that actually break: frontmatter, size, links, and the
# Codex description budget.
#
#   .agents/bin/check-harness.sh
#
# Replaces the useful half of the deleted .agents/evals/startup-context harness.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
S=.claude/skills
fail=0
warn_count=0
note() { echo "  $*"; }
warn() { echo "  WARN  $*"; warn_count=$((warn_count+1)); }
bad()  { echo "  FAIL  $*"; fail=1; }

echo "== frontmatter =="
for f in "$S"/*/SKILL.md; do
  d=$(basename "$(dirname "$f")")
  # Parse the leading YAML block only. Searching the whole file would pass a
  # skill whose keys appear in its body but not its frontmatter — which the
  # budget parser then silently skips and clients cannot discover.
  msg=$(awk -v want="$d" '
    NR==1 && $0!="---" { print "no opening ---"; exit }
    NR>1 && $0=="---" { closed=1; exit }
    NR>1 { if ($0 ~ /^name:[[:space:]]/)        { n=$0; sub(/^name:[[:space:]]*/,"",n); gsub(/^"|"$/,"",n) }
           if ($0 ~ /^description:[[:space:]]/) { desc=1 } }
    END { if (!closed) { print "frontmatter has no closing ---"; exit }
          if (n=="")   { print "no name in frontmatter"; exit }
          if (n!=want) { print "name \"" n "\" does not match directory"; exit }
          if (!desc)   { print "no description in frontmatter" } }' "$f")
  [ -n "$msg" ] && bad "$d: $msg"
done
[ "$fail" = 0 ] && note "ok"

echo "== SKILL.md size (target <=150 lines) =="
over=0
for f in "$S"/*/SKILL.md; do
  l=$(wc -l < "$f" | tr -d ' ')
  [ "$l" -gt 150 ] && { warn "$(dirname "$f") is ${l}L (target 150)"; over=1; }
done
[ "$over" = 0 ] && note "ok"

echo "== relative links resolve =="
broken=0
deps_unchecked=0
while IFS= read -r f; do
  d=$(dirname "$f")
  while IFS= read -r link; do
    case "$link" in http*|"#"*) continue;; esac
    target="${link%%#*}"
    [ -z "$target" ] && continue
    # usage_rules generates repo-root-relative links into deps/, which exists
    # only after `mix deps.get`. On a cold checkout those are unfetched, not
    # broken — counting them as failures makes the check unpassable and trains
    # agents to ignore it.
    case "$target" in deps/*) [ -d deps ] || { deps_unchecked=$((deps_unchecked+1)); continue; };; esac
    [ -e "$d/$target" ] || [ -e "$target" ] || { bad "$f -> $link"; broken=1; }
  # Skip fenced code blocks: a link inside one is an illustration, not a link.
  done < <(awk '/^[[:space:]]*```/{f=!f; next} !f' "$f" | grep -oE '\]\([^)]+\)' | sed 's/](//;s/)$//')
done < <(find "$S" .claude/agents -name '*.md' -not -path "*/create-product-mail/references/*")
[ "$deps_unchecked" != 0 ] && warn "$deps_unchecked deps/ link(s) unchecked — run 'mix deps.get' to resolve them"
[ "$broken" = 0 ] && note "ok"

echo "== Codex skill-listing budget (8000 chars) =="
chars=$(python3 - "$S" <<'PY'
import re, sys, glob, os
tot = 0
for f in glob.glob(os.path.join(sys.argv[1], "*/SKILL.md")):
    m = re.search(r"\A---\n(.*?)\n---", open(f).read(), re.S)
    if not m: continue
    fm = m.group(1)
    n = re.search(r"^name:\s*(.*)", fm, re.M)
    dsc = re.search(r"^description:\s*(.*?)(?=\n[a-z-]+:|\Z)", fm, re.S | re.M)
    if n and dsc: tot += len(n.group(1).strip()) + len(dsc.group(1).strip())
print(tot)
PY
)
n=$(find "$S" -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
if [ "$chars" -gt 8000 ]; then bad "$n skills, $chars chars — OVER by $((chars-8000)); Codex truncates descriptions"
else note "ok: $n skills, $chars chars ($((8000-chars)) to spare)"; fi

echo "== client skill topology =="
# .claude/skills MUST be a real directory: Claude Code in GitHub Actions does not
# resolve symlinks, so a symlinked .claude/skills loses every skill in exactly the
# headless runs the maintenance lanes depend on. Codex resolves symlinks fine, so
# the indirection lives on that side.
sym=0
if [ -L .claude/skills ]; then
  bad ".claude/skills is a symlink — GitHub Actions cannot resolve it. It must be the real directory."
  sym=1
elif [ ! -d .claude/skills ]; then
  bad ".claude/skills is missing"
  sym=1
fi
for l in .agents/skills .codex/skills; do
  if [ ! -L "$l" ]; then bad "$l should be a symlink to ../.claude/skills"; sym=1
  elif [ ! -e "$l/_shared/vocabulary.md" ]; then bad "$l does not resolve to the skills tree"; sym=1
  fi
done
[ -L CLAUDE.md ] || { bad "CLAUDE.md is not a symlink to AGENTS.md"; sym=1; }
[ "$sym" = 0 ] && note "ok"

echo
if [ "$fail" != 0 ]; then
  echo "harness has failures"
elif [ "$warn_count" != 0 ]; then
  echo "harness OK, with $warn_count warning(s)"
else
  echo "harness OK"
fi
exit "$fail"
