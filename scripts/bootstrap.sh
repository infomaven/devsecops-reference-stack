#!/usr/bin/env bash
# Preflight. Run this before a demo so a missing binary is found now and not
# while someone is watching.
set -euo pipefail

required=(docker kind kubectl helm terraform ansible-playbook sops age-keygen conftest)
missing=()

for bin in "${required[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    printf '  ok      %-18s %s\n' "$bin" "$(command -v "$bin")"
  else
    printf '  MISSING %-18s\n' "$bin"
    missing+=("$bin")
  fi
done

if ! python3 -c 'import psycopg2' 2>/dev/null; then
  echo "  MISSING psycopg2          pip install psycopg2-binary"
  missing+=(psycopg2)
fi

if [ ${#missing[@]} -gt 0 ]; then
  echo
  echo "Install the missing items above, then re-run." >&2
  exit 1
fi

echo
echo "All tools present. Next: make cluster"
