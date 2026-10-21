#!/usr/bin/env bash
# Which feature row owns a file? The change protocol says every tracked file
# outside spec/ is listed in the Files column of a row in spec/FEATURES.md,
# and that a file is edited only under the feature (and prompt) that owns it.
#
#   scripts/spec-owner.sh <path>...   print the owning rows; exit 1 if any
#                                     path has no owner
#   scripts/spec-owner.sh --all       check every tracked file; exit 1 and
#                                     list the unowned ones
#   scripts/spec-owner.sh --hook      Claude Code PreToolUse hook: read the
#                                     tool call on stdin, exit 2 (block) if
#                                     the target file has no owner
#
# Files under spec/ are the spec itself (F24) and always pass, as do paths
# outside the repository and paths git ignores. bash 3.2 compatible.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEATURES="$ROOT/spec/FEATURES.md"

# One line per (row, pattern): "ID<TAB>prompt<TAB>pattern", parsed once from
# the Features table's Files column.
TABLE=$(grep -E '^\| F[0-9][0-9] \|' "$FEATURES" | awk -F'|' '{
  id = $2; prompt = $6; gsub(/ /, "", id); gsub(/ /, "", prompt)
  files = $5
  while (match(files, /`[^`]+`/)) {
    print id "\t" prompt "\t" substr(files, RSTART + 1, RLENGTH - 2)
    files = substr(files, RSTART + RLENGTH)
  }
}')

# Print "ID<TAB>prompt" for every row with a pattern that matches the
# repository-relative path in $1. A pattern's * matches across directories,
# as the Files column uses it (findings/*, apps/*).
owners_of() {
  last=""
  while IFS='	' read -r id prompt pat; do
    [ "$id" = "$last" ] && continue
    # shellcheck disable=SC2254  # the pattern is meant to glob
    case "$1" in $pat) printf '%s\t%s\n' "$id" "$prompt"; last=$id ;; esac
  done <<EOT
$TABLE
EOT
}

# Repository-relative form of a path, or nothing if it is outside the repo.
relative() {
  case "$1" in
    "$ROOT"/*) printf '%s' "${1#"$ROOT"/}" ;;
    /*)        ;;
    *)         printf '%s' "${1#./}" ;;
  esac
}

exempt() {  # spec/, ignored by git, or outside the repository
  [ -z "$1" ] && return 0
  case "$1" in spec/*) return 0 ;; esac
  git -C "$ROOT" check-ignore -q -- "$1" 2>/dev/null
}

case "${1:-}" in
  --all)
    unowned=0
    for f in $(git -C "$ROOT" ls-files); do
      case "$f" in spec/*) continue ;; esac
      if [ -z "$(owners_of "$f")" ]; then
        echo "  no owner: $f"
        unowned=$((unowned + 1))
      fi
    done
    [ $unowned -eq 0 ]
    ;;

  --hook)
    input=$(cat)
    file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)
    rel=$(relative "$file")
    exempt "$rel" && exit 0
    found=$(owners_of "$rel")
    if [ -z "$found" ]; then
      {
        echo "Blocked by the change protocol (spec/CHANGE-PROTOCOL.md): $rel"
        echo "has no owning feature row in spec/FEATURES.md. Add it to the Files"
        echo "column of the feature it belongs to, or add a new feature row, and"
        echo "commit that spec change before editing the file."
      } >&2
      exit 2
    fi
    list=$(printf '%s' "$found" | awk -F'\t' '{printf "%s%s (prompt %s)", (NR > 1 ? ", " : ""), $1, $2}')
    jq -n --arg ctx "$rel is owned by $list. Work inside that feature's acceptance criteria; if the change goes beyond them, amend the row (and any numbered prompt that describes the file) first." \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
    ;;

  ""|-h|--help)
    sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
    ;;

  *)
    status=0
    for arg in "$@"; do
      rel=$(relative "$arg")
      if exempt "$rel"; then
        printf '%s\texempt\n' "${rel:-$arg}"
        continue
      fi
      found=$(owners_of "$rel")
      if [ -z "$found" ]; then
        printf '%s\tNO OWNER\n' "$rel"
        status=1
      else
        printf '%s\n' "$found" | sed "s|^|$rel	|"
      fi
    done
    exit $status
    ;;
esac
