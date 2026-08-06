#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env"
  set +a
fi

SOLUTION="$ROOT/__dotnet_template__.slnx"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is required but not installed." >&2
  exit 1
fi

echo "Running shellcheck..."
shellcheck "$ROOT"/scripts/*.sh "$ROOT/.githooks/pre-commit"

"$ROOT/scripts/dotnet-format.sh"
dotnet build "$SOLUTION" --verbosity quiet
dotnet test "$SOLUTION" --no-build --verbosity minimal

echo "All verification checks passed."
