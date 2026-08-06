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
  `.env.example`; the build/test scripts source `.env` when present.
- `opencode.json` configures the Roslyn language server (pinned in
  `.config/dotnet-tools.json`, installed by `dev-setup.sh`). With the experimental
  LSP tool enabled (`OPENCODE_EXPERIMENTAL_LSP_TOOL=true`), prefer the `lsp` tool
  for go-to-definition, find-references, and hover when a symbol is ambiguous or
  spans many files.

## Project layout and wiring

- `src/__dotnet_template__.Core/` is the only library (keep I/O out of it);
  `tests/__dotnet_template__.Core.Tests/` is the only test project. Both are listed
  in `__dotnet_template__.slnx` (`.slnx`, not `.sln`).
- Root `Directory.*` files apply to every project:
  - `Directory.Build.props` — net10.0, `TreatWarningsAsErrors`,
    `EnforceCodeStyleInBuild`, nullable, implicit usings. Don't repeat these in a
    new csproj.
  - `Directory.Packages.props` — central package management (CPM) is enabled.
  - `Directory.Build.targets` — makes internals visible to the `.Tests` assembly.
- The coverage gate lives in the test csproj (via `coverlet.msbuild`); see
  "Packages and tests".

## Guardrails (do not bypass)

- **Code style** is enforced by `.editorconfig` and fails the build
  (`TreatWarningsAsErrors`, `EnforceCodeStyleInBuild`). Style is verified in CI and by
  the pre-commit hook. No `var` (all var-style rules are `error`); Allman braces;
  file-scoped namespaces; `_camelCase` private fields.
- **Formatting** must be clean. `dotnet format` runs in verify mode in the pre-commit
  hook and CI. To auto-format: `FORMAT_APPLY=1 ./scripts/dotnet-format.sh`.
- **Tests and coverage**: the coverage gate is built into `dotnet test` via the
  test csproj (`coverlet.msbuild`): `CollectCoverage=true`, branch coverage,
  `ThresholdStat=total`, threshold from `BRANCH_COVERAGE_THRESHOLD` (default 100).
  `dotnet test` fails when branch coverage drops below it. `./scripts/verify.sh`
  runs shellcheck, format verification, the build, and the gated tests. Plain
  `dotnet build` and the pre-commit hook skip the coverage gate; formatting is
  verified only by `verify.sh` and the pre-commit hook.

## Packages and tests

- Add NuGet dependencies via CPM: put the version in `Directory.Packages.props` and
  reference the package without a version in the csproj. A direct `Version` in a
  csproj fails the build (NU1008).
- Tests use xunit v3, Shouldly (`ShouldBe`), and NSubstitute; these are already wired
  as global usings in the test csproj.
- Internal members are visible to the test project (`InternalsVisibleTo` in
  `Directory.Build.targets`), so test them directly instead of via reflection.
- `CoverletExclude` in the test csproj keeps test-infra packages (xunit,
  NSubstitute, Shouldly, coverlet, Microsoft.TestPlatform) out of the measurement.
  Coverlet measures every project assembly that ships a PDB, so new projects are
  covered automatically — extend `CoverletExclude` only if a dependency's PDB ends
  up in the test output.
- Run a single test with `dotnet test --filter "FullyQualifiedName~<name>"`; add
  `-p:CollectCoverage=false` because a partial run can fail the 100% coverage gate.
  Run `./scripts/verify.sh` before committing.

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
