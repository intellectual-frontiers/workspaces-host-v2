# Implementation Plan: Container/OCI Parity

**Branch**: `002-oci-container-parity` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-oci-container-parity/spec.md`

## Summary

Add `packages.<system>.oci-image` to `flake.nix`, built with
`pkgs.dockerTools.buildLayeredImage` from the *same* evaluated
`homeConfigurations.<system>.config` Phase 1 already produces:
`config.home.packages` becomes the image's `contents`, and the generated
dotfiles (`config.xdg.configFile.*.source`) are copied into `/root/...`
via `extraCommands`. No new flake inputs (`dockerTools` ships in
`nixpkgs`, already an input).

## Technical Context

**Language/Version**: Nix expression language, same `nixpkgs`/
`home-manager` pins as Phase 1.

**Primary Dependencies**: `pkgs.dockerTools` (nixpkgs, no new input).

**Storage**: N/A.

**Testing**: `nix build .#packages.<system>.oci-image` (evaluation +
build gate, folded into `nix flake check` via a `checks` entry is
optional/deferred - see Complexity Tracking); manual `docker load` +
`docker run` smoke test analogous to Phase 1's `home-manager switch`
smoke test, documented in this feature's `quickstart.md`.

**Target Platform**: OCI images target Linux; the derivation evaluates
for all four systems but only builds directly on `x86_64-linux`/
`aarch64-linux` (or via a Linux remote builder from macOS).

**Project Type**: Infrastructure-as-code / container image build, added
to the existing single Nix project.

**Performance Goals**: N/A.

**Constraints**: Must not introduce a hand-maintained Dockerfile or a
second package list that could drift from `home/*.nix`.

**Scale/Scope**: One image, reusing Phase 1's single default profile
(per-persona images are Phase 6's concern, if ever needed).

## Constitution Check

- **Principle I**: No new inputs; image is pinned by the same
  `flake.lock` as Phase 1.
- **Principle II**: The image is built fresh from the flake on every
  `nix build`; there's no "docker commit"-style mutation path.
- **Principle III**: N/A - no secrets touched by this feature.
- **Principle IV**: This *is* Principle IV's deliverable - host and
  container now provably share one closure.
- **Principle V**: Single feature, single PR, building only on Phase 1's
  already-merged module structure.

No violations.

## Project Structure

### Documentation (this feature)

```text
specs/002-oci-container-parity/
├── plan.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
oci/
└── default.nix     # pkgs.dockerTools.buildLayeredImage, takes { pkgs, homeConfig }

flake.nix            # adds packages.<system>.oci-image, refactored so
                      # packages/homeConfigurations/checks share one
                      # `homeConfigurationsFor` computed in the outputs' `let`
```

**Structure Decision**: A single `oci/default.nix` module, parameterized
by `pkgs` and the already-evaluated `homeConfig` (a
`homeConfigurations.<system>` value), so it never re-evaluates the
home-manager module set independently - reinforcing FR-002/FR-003's "same
closure" requirement structurally, not just by convention.

## Complexity Tracking

*No constitution violations - table not needed.*
