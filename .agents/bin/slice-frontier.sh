#!/usr/bin/env bash
# Resolves which slices of an epic are ready to dispatch.
#
#   .agents/bin/slice-frontier.sh <epic-number> [--json]
#
# Sub-issues and dependencies are REST-only and take internal ids, so the edge
# walk is fiddly enough to get wrong by hand. This does that walk and nothing
# else: it reads GitHub, classifies each slice, and prints the `wt` command for
# the ready ones. It creates no branch, spawns no agent, and writes nothing.
#
# Ready means open, every blocker closed, and labelled `afk`. A slice whose
# blockers are closed but which carries no `afk` label is ready for Chris, not
# for an agent — see docs/agents/issue-tracker.md.
set -uo pipefail

usage() {
  echo "usage: slice-frontier.sh <epic-number> [--json]" >&2
  exit 1
}

epic=""
as_json=0
for arg in "$@"; do
  case "$arg" in
    --json) as_json=1 ;;
    *[!0-9]*) usage ;;
    "") usage ;;
    *) epic="$arg" ;;
  esac
done
[ -n "$epic" ] || usage

# Lowercase, non-alphanumerics to single dashes, trimmed, capped at 40 chars.
slug() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' |
    cut -c1-40 |
    sed -E 's/-+$//'
}

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner) || exit 1
[ -n "$repo" ] || { echo "cannot resolve repository" >&2; exit 1; }

epic_title=$(gh api "repos/$repo/issues/$epic" --jq .title) || exit 1
feature_branch="feature/$epic-$(slug "$epic_title")"

# Labels are wrapped in commas so the field is never empty. `read` treats tab as
# IFS whitespace and collapses runs of it, so an empty field would shift `title`
# into `labels` and the `afk` test would end up matching against the title.
subs=$(gh api "repos/$repo/issues/$epic/sub_issues" \
  --jq '.[] | [.number, .state, ("," + ((.labels // []) | map(.name) | join(",")) + ","), .title] | @tsv') || exit 1

if [ -z "$subs" ]; then
  if [ "$as_json" -eq 1 ]; then
    jq -n --argjson epic "$epic" --arg branch "$feature_branch" \
      '{epic: $epic, feature_branch: $branch, slices: []}'
  else
    echo "epic #$epic -> $feature_branch"
    echo "  no sub-issues. \`plan-work\` creates them from an approved PLAN."
  fi
  exit 0
fi

landed=(); blocked=(); needs_chris=(); ready=(); ready_branches=(); objects=()

while IFS=$'\t' read -r number state labels title; do
  [ -n "$number" ] || continue
  open_blockers=""
  if [ "$state" = "open" ]; then
    open_blockers=$(gh api "repos/$repo/issues/$number/dependencies/blocked_by" \
      --jq '.[] | select(.state != "closed") | .number' | tr '\n' ' ') || exit 1
  fi
  open_blockers="${open_blockers% }"

  if [ "$state" = "closed" ]; then
    class=landed
  elif [ -n "$open_blockers" ]; then
    class=blocked
  elif [[ "$labels" == *",afk,"* ]]; then
    class=ready
  else
    class=needs_chris
  fi

  branch="slice/$number-$(slug "$title")"
  line="  #$number $title"
  if [ "$class" = "blocked" ]; then
    line+=$'\n''    blocked by '"$(echo "$open_blockers" | sed -E 's/([0-9]+)/#\1/g; s/ /, /g')"
  fi

  case "$class" in
    landed) landed+=("$line") ;;
    blocked) blocked+=("$line") ;;
    needs_chris) needs_chris+=("$line") ;;
    ready) ready+=("$line"); ready_branches+=("$branch") ;;
  esac

  objects+=("$(jq -n \
    --argjson number "$number" --arg title "$title" --arg state "$class" \
    --arg branch "$branch" --arg blockers "$open_blockers" \
    '{number: $number, title: $title, state: $state,
      open_blockers: ($blockers | if . == "" then [] else split(" ") | map(tonumber) end),
      branch: $branch}')")
done <<< "$subs"

if [ "$as_json" -eq 1 ]; then
  printf '%s\n' "${objects[@]}" |
    jq -s --argjson epic "$epic" --arg branch "$feature_branch" \
      '{epic: $epic, feature_branch: $branch, slices: .}'
  exit 0
fi

echo "epic #$epic -> $feature_branch"

print_group() {
  local heading=$1; shift
  [ "$#" -gt 0 ] || return 0
  printf '\n%s (%d)\n' "$heading" "$#"
  printf '%s\n' "$@"
}

print_group "landed" ${landed+"${landed[@]}"}
print_group "blocked" ${blocked+"${blocked[@]}"}
print_group "ready, needs Chris (no \`afk\`)" ${needs_chris+"${needs_chris[@]}"}
print_group "READY" ${ready+"${ready[@]}"}

[ "${#ready_branches[@]}" -gt 0 ] || exit 0

printf '\ndispatch this wave (one worktree each, all cut from %s):\n' "$feature_branch"
for branch in "${ready_branches[@]}"; do
  echo "  wt switch --create $branch --base $feature_branch -y --no-cd"
done
printf '\nThen hand each `slice-implementer` every row of build/SKILL.md §3'"'"'s table.\n'
echo "Wait for this wave's pull requests to land before resolving the next one."
