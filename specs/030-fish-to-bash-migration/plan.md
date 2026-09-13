# Implementation Plan: Replace fish with bash, Add fish-like Interactive Tooling, Preinstall Modern CLI Replacements

**Branch**: `030-fish-to-bash-migration` | **Date**: 2026-09-13 | **Spec**: [spec.md](./spec.md)

## Summary

Remove fish from every layer of the repo (Nix home-manager modules,
OCI image definitions, `install.sh`, `doctor`, the constitution,
README) and make bash the default interactive shell, per the user's
explicit decision overriding feature 029's own recommendation. Replace
fish's native interactive conveniences with bash-native equivalents
(ble.sh for syntax highlighting/autosuggestions, fzf for fuzzy search,
zoxide for directory jumping). Reimplement the credential-scoping
wrapper mechanism (feature 023) in bash. Preinstall and, where safe,
alias modern Rust-based CLI tool replacements the user asked about
(`eza` in place of the deprecated `exa`, plus `bat`, `ripgrep`, `fd`,
`du-dust`, `bottom`, `tealdeer`, `zellij`, wired via `programs.git.delta`
for git). Fix a real activation-blocking bug this migration surfaced
(`HOME_MANAGER_BACKUP_EXT` needed against a fresh account's pre-existing
skeleton dotfiles).

## Technical Context

**Language/Version**: Nix (home-manager modules, OCI image
definitions), POSIX `/bin/sh` (`install.sh`, `pkgs/doctor/doctor`),
bash (generated `.bashrc`/`.bash_profile`/`.profile`), Markdown
(constitution, README).

**Primary Dependencies**: `ble.sh` (via nixpkgs `blesh`), `fzf`,
`zoxide`, `eza`, `bat`, `ripgrep`, `fd`, `du-dust`, `bottom`,
`tealdeer`, `zellij`, `git-delta` (via `programs.git.delta`) - all
resolved from this flake's pinned nixpkgs, verified present by
inspecting the actual pinned package set
(`(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.<system>`)
rather than assumed from memory.

**Testing**: Real `nix build
.#homeConfigurations.current.activationPackage --impure` + activation
(with `HOME_MANAGER_BACKUP_EXT` set, since this sandbox's own account
already has non-symlink `.bashrc`/`.profile`); `doctor` run against the
activated profile; the credential-wrapper bash functions exercised
live end to end with a fake secret file and fake target binary; both
`.#oci-image` and `.#oci-image-sandboxed` built for real; `nix flake
check --all-systems` run across the whole repo.

**Constraints**: This session's remote sandbox has no real TTY
(confirmed via `tty` and `stty -a`), so ble.sh's live interactive
rendering cannot be fully verified here - the Nix-level wiring (correct
store path, correct `mkOrder` placement in the generated `.bashrc`) is
verified by inspection instead, with the limitation documented rather
than glossed over. Credential env vars must remain per-invocation
scoped under bash's function-scoped (not fish's block-scoped) `local`
semantics - verified directly, not assumed.

## Constitution Check

- **Principle I**: every added tool (`blesh`, `fzf`, `zoxide`, `eza`,
  `bat`, `ripgrep`, `fd`, `du-dust`, `bottom`, `tealdeer`, `zellij`,
  `git-delta`) comes from this flake's pinned nixpkgs, not an
  imperative install step. `oh-my-posh enable autoupgrade` remains
  rejected for fighting the read-only Nix store (unchanged from feature
  029).
- **Principle II**: OCI image definitions updated in lockstep so a
  clean container build stays fully working, not just the WSL/host
  path.
- **Principle III**: the credential-scoping wrapper's bash
  reimplementation preserves the exact per-invocation-only exposure
  guarantee; re-verified empirically for bash's different scoping
  rules rather than assumed to carry over from fish's implementation.
- **Principle IV**: both `.#oci-image` and `.#oci-image-sandboxed`
  built and confirmed successful with the bash-based changes, not just
  the host `home-manager switch` path.
- **Principle V**: scoped as its own single spec/PR, covering exactly
  the fish-to-bash migration and its directly-dependent tooling/doc
  changes; no unrelated concerns bundled in.
- **Governance**: the Shell UX constraint amendment is recorded
  explicitly in `.specify/memory/constitution.md` with a version bump
  and dated reasoning, per the amendment process.

No violations.

## Project Structure

```text
flake.nix                                  # updated: description string, fish -> bash
home/shell.nix                             # rewritten: programs.bash + ble.sh/fzf/zoxide wiring, oh-my-posh bash integration
home/ai-harness.nix                        # rewritten: wrapCli generates bash functions instead of fish functions
home/tools.nix                             # updated: added bottom, du-dust, tealdeer, zellij, blesh; removed redundant plain fzf entry
home/git.nix                               # updated: programs.git.delta wired
home/java.nix                              # unchanged - its fish mention is accurate predecessor-repo history
oci/default.nix                            # updated: copies bash dotfiles instead of fish config; Cmd = bash -l
oci/sandboxed.nix                          # updated: same bash-dotfile change
oci/sandboxed-entrypoint.sh                # updated: set -- bash -l instead of fish
install.sh                                 # updated: chsh targets bash's stable path; HOME_MANAGER_BACKUP_EXT set before activation
pkgs/doctor/doctor                         # updated: bash-equivalent checks replacing fish-specific ones; new ble.sh/delta wiring checks
pkgs/workspaces-host-update/workspaces-host-update  # updated: comment fixed from fish syntax to bash syntax
.specify/memory/constitution.md            # amended: Shell UX constraint, version bump
README.md                                  # updated: shell-switch framing throughout, new "Your shell" section
```

## Rollout Notes

This is a breaking change for anyone who already activated a fish-based
profile from this repo: their next `home-manager switch` removes fish's
generated config and switches their login shell (best-effort, same
warn-not-abort pattern as feature 029) to bash. This is accepted as the
correct behavior per the user's explicit instruction to "remove fish
and fix everything from there," rather than maintaining both shells or
a migration flag - Constitution Principle II (ephemeral/disposable,
rebuild rather than patch) treats this the same as any other profile
change.
