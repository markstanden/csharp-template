#!/usr/bin/env bash
set -euo pipefail

# dev-setup.sh [project-name]
#
# Bootstraps the development environment for this repository:
#   1. Renames the '__dotnet_template__' placeholder to [project-name] (file and
#      folder names, plus file contents) when a name argument is given.
#   2. Verifies required dev dependencies and installs missing ones where possible.
#   3. Installs git hooks (core.hooksPath -> .githooks).
#   4. Creates `.env` from `.env.example` if missing (app/script overrides).
#
# Keep this script in sync with the dev environment (see AGENTS.md).
# Safe to run repeatedly; the rename is skipped once the placeholder is gone.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOTNET_MAJOR="10"
PLACEHOLDER="__dotnet_template__"

say()  { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

PROJECT_NAME="${1:-}"

if [[ "$PROJECT_NAME" == "--help" || "$PROJECT_NAME" == "-h" ]]; then
  say "Usage: ./scripts/dev-setup.sh [project-name]"
  echo "  [project-name]  Rename the '$PLACEHOLDER' placeholder to this name across"
  echo "                  the repository (file/folder names and contents), then set"
  echo "                  up dependencies, hooks, and the environment."
  echo "                  Omit it to skip the rename step."
  exit 0
fi

if [[ $# -gt 1 ]]; then
  fail "Usage: ./scripts/dev-setup.sh [project-name]"
fi

# 0. Rename the template placeholder ------------------------------------------

placeholder_remains() {
  if find "$ROOT" -not -path '*/.git/*' -not -path '*/bin/*' -not -path '*/obj/*' \
      -not -path '*/TestResults/*' -name "*$PLACEHOLDER*" -print -quit | grep -q .; then
    return 0
  fi
  if grep -rq -I --exclude=dev-setup.sh --exclude-dir=.git --exclude-dir=bin \
      --exclude-dir=obj --exclude-dir=TestResults "$PLACEHOLDER" "$ROOT" 2>/dev/null; then
    return 0
  fi
  return 1
}

delete_readme_section() {
  local readme="$ROOT/README.md"
  if [[ ! -f "$readme" ]]; then
    return 0
  fi

  awk '
    BEGIN { skip = 0 }
    /^## Creating a new project from this template/ { skip = 1; next }
    skip && /^## / { skip = 0 }
    !skip { print }
  ' "$readme" > "${readme}.tmp" && mv "${readme}.tmp" "$readme"
}

rename_project() {
  local name="$1"

  if [[ ! "$name" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
    fail "Invalid project name '$name'. Use letters, digits, and underscores, starting with a letter."
  fi
  if [[ ! "$name" =~ ^[A-Z] ]]; then
    warn "Project name '$name' is not PascalCase (expected an uppercase first letter)."
  fi

  if ! placeholder_remains; then
    warn "Placeholder '$PLACEHOLDER' was not found; nothing to rename."
    return 0
  fi

  say "Renaming placeholder '$PLACEHOLDER' to '$name'..."

  # 1. Rename files in place (source and destination share a directory, so this
  #    works before the containing folders are renamed).
  while IFS= read -r -d '' f; do
    dir="$(dirname "$f")"
    base="$(basename "$f")"
    mv "$f" "$dir/${base//$PLACEHOLDER/$name}"
  done < <(find "$ROOT" -type f -name "*$PLACEHOLDER*" -not -path '*/.git/*' \
    -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/TestResults/*' -print0)

  # 2. Rename directories, deepest first.
  while IFS= read -r -d '' d; do
    parent="$(dirname "$d")"
    base="$(basename "$d")"
    mv "$d" "$parent/${base//$PLACEHOLDER/$name}"
  done < <(find "$ROOT" -depth -type d -name "*$PLACEHOLDER*" -not -path '*/.git/*' \
    -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/TestResults/*' -print0)

  # 3. Replace the placeholder in file contents. This script is excluded: it is
  #    the renamer and must always know the canonical placeholder name.
  while IFS= read -r -d '' f; do
    sed -i "s/$PLACEHOLDER/$name/g" "$f"
  done < <(grep -rl -I -Z --exclude=dev-setup.sh --exclude-dir=.git --exclude-dir=bin \
    --exclude-dir=obj --exclude-dir=TestResults "$PLACEHOLDER" "$ROOT" 2>/dev/null)

  # 4. Drop the template-only README section.
  delete_readme_section

  printf '     renamed %s to %s\n' "$PLACEHOLDER" "$name"
}

if [[ -n "$PROJECT_NAME" ]]; then
  rename_project "$PROJECT_NAME"
else
  if placeholder_remains; then
    warn "The template placeholder is still present. Run './scripts/dev-setup.sh <ProjectName>' to rename it."
  fi
fi

# 1. Dev dependencies --------------------------------------------------------

say "Checking dev dependencies..."

require_command() {
  local cmd="$1" label="${2:-$1}"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'ok   %s\n' "$label"
    return 0
  fi
  printf 'missing   %s\n' "$label"
  return 1
}

install_via_apt() {
  local pkg="$1"
  if ! command -v apt-get >/dev/null 2>&1; then
    return 1
  fi
  say "Installing $pkg via apt-get..."
  if [[ "$(id -u)" -eq 0 ]]; then
    apt-get update || return 1
    apt-get install -y "$pkg" || return 1
  else
    sudo apt-get update || return 1
    sudo apt-get install -y "$pkg" || return 1
  fi
}

if ! require_command git "git"; then
  fail "git is required to develop this repository. Install it and re-run this script."
fi

if ! require_command shellcheck "shellcheck (script linting)"; then
  if ! install_via_apt shellcheck; then
    warn "Could not install shellcheck automatically. Install it from https://www.shellcheck.net/ and re-run."
  else
    printf 'ok   shellcheck (installed via apt-get)\n'
  fi
fi

if ! require_command dotnet ".NET SDK ${DOTNET_MAJOR}.x"; then
  fail "The .NET SDK is not installed. Install it from https://dotnet.microsoft.com/download (SDK ${DOTNET_MAJOR}.0+) and re-run this script."
fi

DOTNET_VERSION="$(dotnet --version)"
if [[ "$DOTNET_VERSION" != "$DOTNET_MAJOR."* ]]; then
  fail "Found .NET SDK $DOTNET_VERSION; this repository targets .NET ${DOTNET_MAJOR}.x."
fi
printf 'ok   dotnet SDK %s\n' "$DOTNET_VERSION"

# dotnet new templates may not preserve the executable bit, so re-assert it.
chmod +x "$ROOT"/scripts/*.sh "$ROOT/.githooks/pre-commit"

# 2. Git hooks ----------------------------------------------------------------

say "Installing git hooks (core.hooksPath)..."
git config core.hooksPath "$ROOT/.githooks"
printf '     hooks installed at %s\n' "$ROOT/.githooks"

# 3. Environment overrides ----------------------------------------------------

say "Setting up environment overrides (.env)..."
ENV_FILE="$ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  printf '     .env already exists; leaving it untouched.\n'
else
  cp "$ROOT/.env.example" "$ENV_FILE"
  printf '     created .env from .env.example\n'
fi

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a
printf '     loaded: FORMAT_ANALYZER_SEVERITY=%s, BRANCH_COVERAGE_THRESHOLD=%s\n' \
  "${FORMAT_ANALYZER_SEVERITY:-warn}" "${BRANCH_COVERAGE_THRESHOLD:-100}"

say "Dev setup complete. Run ./scripts/verify.sh to confirm the toolchain."
