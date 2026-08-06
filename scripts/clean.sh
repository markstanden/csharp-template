#!/usr/bin/env bash
set -euo pipefail

# clean.sh [--dry-run]
#
# Recursively removes build/test artifacts (bin/, obj/, TestResults/, coverage
# output, and other temp files) so the repository can be built from a clean slate.
# Nothing inside `.git` is ever touched. Safe to run repeatedly.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/.gitignore" ]]; then
  echo "ERROR: $(basename "$0") must live in the repository's scripts/ directory." >&2
  exit 1
fi

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
elif [[ -n "${1:-}" ]]; then
  echo "ERROR: unknown argument '$1'. Usage: ./scripts/clean.sh [--dry-run]" >&2
  exit 1
fi

say() { printf '==> %s\n' "$*"; }

remove() {
  if [[ "$DRY_RUN" == true ]]; then
    printf 'would remove %s\n' "$1"
  else
    printf 'removing %s\n' "$1"
    rm -rf "$1"
  fi
}

found_any=false

# Known build/test artifact directories.
while IFS= read -r -d '' d; do
  remove "${d#"$ROOT"/}"
  found_any=true
done < <(find "$ROOT" -type d -name .git -prune -o \
  -type d \( -name bin -o -name obj -o -name TestResults -o -name TestResult \
    -o -name CodeCoverage \) -prune -print0)

# Known artifact files.
while IFS= read -r -d '' f; do
  remove "${f#"$ROOT"/}"
  found_any=true
done < <(find "$ROOT" -type d -name .git -prune -o \
  -type f \( -name '*.tmp' -o -name '*.bak' -o -name '*.binlog' \
    -o -name 'TestResult.xml' -o -name 'nunit-*.xml' \) -print0)

if [[ "$found_any" == false ]]; then
  say "Nothing to clean."
elif [[ "$DRY_RUN" == true ]]; then
  say "Dry run complete; nothing was removed."
else
  say "Clean complete. Run ./scripts/verify.sh for a full clean build."
fi
