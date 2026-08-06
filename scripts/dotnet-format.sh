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

# Analyzer severity for `dotnet format analyzers` (style rules enforced via build).
ANALYZER_SEVERITY="${FORMAT_ANALYZER_SEVERITY:-warn}"

run_format() {
  local verify_flag=("$@")

  echo "Formatting whitespace..."
  dotnet format "$SOLUTION" whitespace "${verify_flag[@]}" --verbosity normal

  echo "Formatting analyzers..."
  dotnet format "$SOLUTION" analyzers "${verify_flag[@]}" --severity "$ANALYZER_SEVERITY" --verbosity normal
}

if [[ "${FORMAT_APPLY:-0}" == "1" ]]; then
  echo "Applying dotnet format (whitespace + analyzers)..."
  run_format
  echo "Format applied."
  exit 0
fi

echo "Verifying dotnet format (whitespace + analyzers, no changes allowed)..."
run_format --verify-no-changes

echo "Verifying code style via build (EditorConfig errors)..."
dotnet build "$SOLUTION" --no-restore --verbosity quiet

echo "Format verification passed."
