# Implementation Plan: Workspace Repo Management (mgit)

**Branch**: `010-workspace-repo-management` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `pkgs/mgit` - a POSIX-shell reimplementation of
`strategy-coach/workspaces`'s `mgit.ts`/`ws-ensure.ts` (clone-or-pull by
governed `host/org/repo` layout, `*.mgit.code-workspace` symlinking and
recursive dependent-repo resolution, status/inspect reporting) - installed
by every profile via the existing `pkgs/default.nix` aggregation. Add
`home/workspaces.nix` to bootstrap `~/workspaces` and an empty
`mgit.json` on first activation. Extend `pkgs/doctor/doctor` with checks
for `mgit` and the workspace directory/config. Document the whole
workflow in README.md, replacing the original's two-repo setup story.

## Technical Context

**Language/Version**: POSIX `/bin/sh` (matches `pkgs/mgitstatus`,
`pkgs/sensitivectl`), wrapped via `pkgs.stdenvNoCC.mkDerivation` +
`makeWrapper`, same as every other `pkgs/*` tool in this repo.

**Primary Dependencies**: `git`, `jq`, `findutils`, `coreutils`, `gnugrep`,
`gnused` (all already used elsewhere in this repo), plus this repo's own
`mgitstatus` package (reused for the `status` subcommand rather than
duplicating its git-status logic).

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation to confirm `~/workspaces/mgit.json` bootstraps correctly
and doesn't get clobbered on a second activation; `mgit ensure` against a
real public repo (clone, then a second run to confirm it pulls instead);
a synthetic `*.mgit.code-workspace` fixture (sourcing just the script's
function definitions, to test `resolve_workspace_deps` without needing a
real second repo to clone) to verify symlinking and recursive dependent-repo
resolution, including that a self-referencing/failing entry doesn't abort
the run or infinite-loop.

**Constraints**: No Deno runtime, no vendored third-party TypeScript
dependencies - see spec's Assumptions for why a shell reimplementation
was chosen over porting the original source directly.

## Constitution Check

- **Principle I**: No new flake inputs; `mgit` is built entirely from
  packages already provided by the pinned `nixpkgs` input.
- **Principle IV**: N/A - `~/workspaces` is a host-side working-directory
  convention, not a container/OCI concern.
- **Principle V**: Single feature, single PR (the largest of this
  project's `pkgs/*` additions so far, but still one self-contained
  capability).

No violations.

## Project Structure

```text
pkgs/mgit/mgit           # new: ensure/status/inspect POSIX shell tool
pkgs/mgit/default.nix    # new: package definition
pkgs/default.nix         # updated: register mgit
home/workspaces.nix      # new: bootstrap ~/workspaces + mgit.json
home/default.nix         # updated: import ./workspaces.nix
pkgs/doctor/doctor       # updated: mgit + ~/workspaces checks
README.md                # new "Managing your ~/workspaces repos" section
```
