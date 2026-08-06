#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ROOT/.env"
  set +a
fi

RESULTS="$ROOT/tests/__dotnet_template__.Core.Tests/TestResults"
THRESHOLD="${BRANCH_COVERAGE_THRESHOLD:-100}"

dotnet test "$ROOT/tests/__dotnet_template__.Core.Tests/__dotnet_template__.Core.Tests.csproj" \
  --collect:"XPlat Code Coverage" \
  --settings "$ROOT/coverlet.runsettings" \
  --verbosity quiet

REPORT="$(find "$RESULTS" -name 'coverage.cobertura.xml' -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)"
BRANCH_RATE="$(grep -m1 'branch-rate=' "$REPORT" | sed -E 's/.*branch-rate="([^"]+)".*/\1/')"
BRANCH_PCT="$(awk "BEGIN { printf \"%.2f\", $BRANCH_RATE * 100 }")"

echo "__dotnet_template__.Core branch coverage: ${BRANCH_PCT}%"

awk -v rate="$BRANCH_RATE" -v threshold="$THRESHOLD" 'BEGIN {
  if (rate * 100 + 0.001 < threshold) {
    printf "Coverage gate failed: %.2f%% < %s%%\n", rate * 100, threshold;
    exit 1;
  }
}'

echo "Coverage gate passed."
