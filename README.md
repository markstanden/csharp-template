# __dotnet_template__

Starter template with engineering guardrails wired in from the first commit:
strict code-style enforcement, warnings-as-errors, formatting verification,
git hooks, a 100% branch-coverage gate, and CI.

## Prerequisites

- .NET SDK 10.x — https://dotnet.microsoft.com/download
- shellcheck — https://www.shellcheck.net/
- git

## Creating a new project from this template

This is a copy-and-replace starter (not a `dotnet new` template). `__dotnet_template__`
is the placeholder project name — file/folder names, namespaces, and script paths all
use it. To start a new project, run setup with your project name: it renames the
placeholder throughout the repository, then installs hooks and the environment.

```bash
./scripts/dev-setup.sh MyApp   # rename placeholder to MyApp, install hooks, create .env
./scripts/verify.sh            # shellcheck + format + build + tests + coverage gate
```

This section is removed automatically by the rename step.

## Development workflow

| Action | Command |
|--------|---------|
| Verify everything (format, build, tests, coverage) | `./scripts/verify.sh` |
| Auto-format code | `FORMAT_APPLY=1 ./scripts/dotnet-format.sh` |
| Clean all build/test artifacts | `./scripts/clean.sh` |
| Run tests | `dotnet test` |
| Build | `dotnet build` |

The pre-commit hook verifies formatting on every commit; CI runs the same checks as
`verify.sh` on push to `main` and on pull requests.

## Layout

- `src/__dotnet_template__.Core/` — domain logic (keep I/O out of this project)
- `tests/__dotnet_template__.Core.Tests/` — tests for the core project
- `config/` — runtime configuration for the app
- `scripts/` — dev tooling (`verify.sh`, `dotnet-format.sh`, `test-coverage.sh`, `clean.sh`, `dev-setup.sh`)
- `.githooks/` — git hooks (installed by `dev-setup.sh`)
- `.github/workflows/` — CI

## Env overrides

See `.env.example`. `dev-setup.sh` creates `.env` from it, and the build/test
scripts source it when present. Overrides include `FORMAT_ANALYZER_SEVERITY`
and `BRANCH_COVERAGE_THRESHOLD`.
