# Implementation Plan: Agent-Harness Scaffolding

**Branch**: `003-agent-harness-scaffolding` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-agent-harness-scaffolding/spec.md`

## Summary

Package `specify-cli` (Python, GitHub Spec Kit) and `backlog-md` (a thin
Node wrapper around a prebuilt native binary) as flake packages; add a
`templates/agent-harness/` directory holding the agent-harness convention
files; package a `scaffold-agent-harness` shell command that copies that
template into a target project non-destructively. All three land in the
default home-manager profile's `home.packages`.

## Technical Context

**Language/Version**: Nix (packaging), Python 3.12 (specify-cli, built via
`buildPythonApplication`), POSIX `sh` (`scaffold-agent-harness`, matching
this repo's other ported scripts).

**Primary Dependencies**: `pkgs.python3Packages` (typer, click, rich,
platformdirs, readchar, pyyaml, packaging, pathspec, json5 - typer and
json5 bumped past nixpkgs' pin via `overridePythonAttrs` +
`pythonRelaxDeps`, since specify-cli's own runtime-deps check enforces its
pyproject.toml's declared minimums); `pkgs.nodejs` (backlog-md's wrapper
runtime); `pkgs.makeWrapper` (both `backlog-md` and
`scaffold-agent-harness`).

**Storage**: N/A.

**Testing**: `nix build` of each new package, then a functional smoke
test per package (`specify check`, `specify init --here` against a
scratch dir; `backlog --help`; `scaffold-agent-harness` against a scratch
dir, run twice to prove the skip-if-exists behavior) - documented in this
feature's `quickstart.md`.

**Target Platform**: `backlog-md` fetches a platform-specific compiled
binary (linux-x64/linux-arm64/darwin-x64/darwin-arm64) selected by
`pkgs.stdenv.hostPlatform.system`; `specify-cli` and
`scaffold-agent-harness` are pure/portable across all four systems.

**Project Type**: Additions to the existing single Nix project (new
`pkgs/*` packages, a new `templates/` directory, no new flake inputs).

**Performance Goals**: N/A.

**Constraints**: No new flake inputs - both CLIs are fetched via
`pkgs.fetchurl`/`builtins.fetchGit` against PyPI/npm/GitHub directly, not
via a new pinned flake dependency. `pkgs.fetchgit` (a sandboxed
fixed-output derivation) can't validate this sandbox's egress-proxy TLS
certificate, so `specify-cli`'s source uses `builtins.fetchGit` instead
(evaluated by the nix CLI process itself, which does trust it - same
mechanism `flake.nix`'s own `git+https` inputs already rely on).

**Scale/Scope**: Two CLI packages, one template directory, one scaffold
command. Per-persona template variants (e.g. a leaner AGENTS.md for a
narrow profile) are out of scope - Phase 6's concern if ever needed.

## Constitution Check

- **Principle I**: Both CLIs are pinned (specify-cli to an exact commit,
  backlog-md to an exact npm version + integrity hash); no install-time
  resolution against a mutable upstream.
- **Principle II**: `scaffold-agent-harness` only ever adds files, never
  mutates in place - re-running it after a rebuild is safe and matches
  the disposable/rebuild-don't-patch philosophy.
- **Principle III**: N/A - no secrets. The template's `.mcp.json` and
  `.claude/settings.json` contain no credentials.
- **Principle IV**: These packages flow through `home.packages` like
  everything else, so Phase 2's OCI image picks them up automatically
  with no separate image-side listing.
- **Principle V**: Single feature, single PR, building only on already-
  merged Phase 1/2 structure.

No violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-agent-harness-scaffolding/
├── plan.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
pkgs/
├── specify-cli/default.nix         # buildPythonApplication, builtins.fetchGit source
├── backlog-md/default.nix          # fetchurl (npm tarballs) + makeWrapper
└── scaffold-agent-harness/
    ├── default.nix                 # stdenvNoCC.mkDerivation + makeWrapper
    └── scaffold-agent-harness       # the POSIX sh script itself

templates/agent-harness/
├── AGENTS.md
├── .mcp.json
└── .claude/
    ├── settings.json
    ├── hooks/session-start.sh
    └── skills/README.md

home/tools.nix                       # unchanged in structure - already
                                      # installs everything pkgs/default.nix
                                      # aggregates, so the two new CLIs and
                                      # the scaffold command land on PATH
                                      # with no edit needed here
```

**Structure Decision**: New packages under `pkgs/`, matching the existing
`semtag`/`mgitstatus`/`git-standup` layout; a new top-level `templates/`
directory (parallel to `.specify/templates/`, but for this feature's own
convention rather than Spec Kit's) so the scaffolded content is reviewable
as plain files rather than embedded strings in a script.

## Complexity Tracking

*No constitution violations - table not needed.*
