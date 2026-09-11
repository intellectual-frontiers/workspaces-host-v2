# Implementation Plan: Workspace Profiles

**Branch**: `006-workspace-profiles` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

## Summary

Add `home/profiles/{backend,data,mobile,agent-ops}.nix`, each a small
home-manager module adding only `home.packages`. Refactor `flake.nix`'s
`mkHomeConfiguration` to take an `extraModules` list, and expose
`homeConfigurations.<persona>` for each, composed from the same base
`./home` module set plus exactly one persona module.

## Technical Context

**Language/Version**: Nix.

**Primary Dependencies**: `postgresql`, `redis`, `docker-compose`,
`httpie` (backend); `python3`, `uv`, `duckdb` (data); `android-tools`,
`watchman` (mobile); `gh`, `act` (agent-ops) - all already in nixpkgs, no
new flake input.

**Storage**: N/A.

**Testing**: `nix build .#homeConfigurations.<persona>.activationPackage`
for all four, plus a real activation of one (`backend`) to confirm both
base and persona-specific tools resolve on `PATH` - not just a build
success.

**Target Platform**: Persona configurations are pinned to `x86_64-linux`,
matching `default`'s own precedent from Phase 1.

**Project Type**: Additions to the existing single Nix project.

**Constraints**: A persona module must be purely additive
(`home.packages` only) - see spec FR-002. No new flake inputs.

**Scale/Scope**: Four personas, 2-4 packages each. Combining multiple
personas into one active profile, and per-system persona configurations,
are both explicitly out of scope (spec Edge Cases/Assumptions).

## Constitution Check

- **Principle I**: No new inputs; all persona packages pinned by the
  existing `flake.lock`.
- **Principle II**: Each persona is a from-scratch `home-manager switch`
  target, not a patch applied on top of another profile's live state.
- **Principle III**: N/A - no secrets involved.
- **Principle IV**: Persona profiles aren't wired into the OCI images in
  this feature (out of scope - Phase 2's images stay on the base
  profile); nothing here prevents a later feature from doing so the same
  way `oci/default.nix` already parameterizes on `homeConfig`.
- **Principle V**: Single feature, single PR.

No violations.

## Project Structure

```text
home/profiles/
├── backend.nix
├── data.nix
├── mobile.nix
└── agent-ops.nix

flake.nix                # mkHomeConfiguration gains an extraModules
                          # parameter; personaModules + personaConfigurations
                          # added; homeConfigurations gains the four names

specs/006-workspace-profiles/
├── plan.md
├── quickstart.md
└── tasks.md
```

**Structure Decision**: `home/profiles/` sits alongside `home/*.nix`
(the base modules) as a clearly-separate subdirectory, so it's visually
obvious which files are shared-base vs. persona-additive.

## Complexity Tracking

*No constitution violations - table not needed.*
