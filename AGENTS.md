# AGENTS.md

Guidance for AI agents and humans working in this repository.

## Development environment

- If the project name is still the template placeholder, run
  `./scripts/dev-setup.sh <Name>` to rename it across the repository (file/folder
  names and contents). Do not rename the placeholder by hand.
- Run `./scripts/dev-setup.sh` after cloning and whenever the toolchain changes
  (passing the project name while the placeholder is present). It checks/installs
  dev dependencies, installs git hooks (`core.hooksPath`), and creates `.env` from
  `.env.example`.
- **Keep `scripts/dev-setup.sh` up to date.** Whenever a new dev dependency (a tool
  required to build, test, or lint) is introduced, or the app starts reading a new
  environment variable, update `scripts/dev-setup.sh` (and `.env.example` / `.env`
  documentation) to match. It is the source of truth for the dev environment.
- Environment variables that affect the build/test toolchain are documented in
  `.env.example`.

## Guardrails (do not bypass)

- **Code style** is enforced by `.editorconfig` and fails the build
  (`TreatWarningsAsErrors`, `EnforceCodeStyleInBuild`). Style is verified in CI and by
  the pre-commit hook. No `var` for built-in types; Allman braces; file-scoped
  namespaces; `_camelCase` private fields.
- **Formatting** must be clean. `dotnet format` runs in verify mode in the pre-commit
  hook and CI. To auto-format: `FORMAT_APPLY=1 ./scripts/dotnet-format.sh`.
- **Tests and coverage**: `./scripts/verify.sh` runs shellcheck, format verification,
  the build, and tests. Branch coverage must meet `BRANCH_COVERAGE_THRESHOLD`
  (default 100%).

## Workflow

1. Create a failing test for the new behaviour
2. Make a change.
3. Add or adjust tests — new logic must be covered (100% branch-coverage gate).
4. Run `./scripts/verify.sh` locally before committing.
5. The pre-commit hook re-checks formatting on commit.
6. CI runs the same verification on push to `main` and on pull requests.

To rebuild from a clean slate (e.g. to confirm there are no stale artifacts), run
`./scripts/clean.sh` first — it removes `bin/`, `obj/`, `TestResults/`, coverage
output, and other temp files recursively (never inside `.git`). Use `--dry-run` to
preview.

## Documentation conventions

- `RULES.md` — human-readable specification of the domain behaviour. Keep it in sync
  when behaviour changes. It ships as a stub to replace for the new project.
- `PLAN.md` — the current plan / roadmap (also a stub).
- `README.md` — getting started and project overview.
