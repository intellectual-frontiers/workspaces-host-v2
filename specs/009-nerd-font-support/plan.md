# Implementation Plan: Nerd Font Support

**Branch**: `009-nerd-font-support` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add `home/fonts.nix`, installing a patched JetBrainsMono Nerd Font via
`pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }` plus
`fonts.fontconfig.enable`, imported into every profile via `home/default.nix`.
Document the exact font family name and the manual per-terminal-emulator
selection steps in README.md, since that half of the problem is not
automatable by home-manager.

## Technical Context

**Language/Version**: Nix (home-manager module), unchanged nixpkgs pin
(24.11, nerd-fonts version 3.2.1 as pinned there).

**Primary Dependencies**: `pkgs.nerdfonts` (nixpkgs 24.11's font packaging
interface - the pre-split form, not the newer `pkgs.nerd-fonts.<name>`),
fetched from `github.com/ryanoasis/nerd-fonts` release assets.

**Testing**: `nix build .#homeConfigurations.default.activationPackage`;
real activation as the flake's configured `workspace` user; `fc-list` against
the activated profile to get the *exact* installed family names (not
assumed) before writing them into README.md.

**Constraints**: No terminal-emulator auto-configuration (see spec Edge
Cases) - documentation only for that half.

## Constitution Check

- **Principle I**: No new flake inputs; `nerdfonts` comes from the existing
  pinned `nixpkgs` input.
- **Principle IV**: N/A - a font is a host-side terminal-rendering concern,
  not something the OCI image needs (containers are typically accessed via
  a host terminal that already has its own font).
- **Principle V**: Single small feature, single PR.

No violations.

## Project Structure

```text
home/fonts.nix       # new: nerdfonts package + fontconfig
home/default.nix     # updated: import ./fonts.nix
README.md            # new step 6 under Installation: manual font-selection instructions
```
