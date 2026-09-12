# Implementation Plan: README Outcomes Framing & Beginner-Friendly Onboarding

**Branch**: `016-readme-outcomes-and-onboarding` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Full rewrite of README.md: strip every reference to this repository's own
predecessor/origin story in favor of outcomes-first framing; restructure
Installation to lead with a single-user, no-systemd, no-manual-file-edit
WSL walkthrough aimed at a first-time Windows user, with Linux/macOS
expressed as short deltas; add a new "Updating your Git identity, and
other secrets, from the CLI" section (git identity via a one-line `sed`
command, `.pgpass` via a CLI append, tokens via the existing sops/age +
direnv mechanism, all reordered from simplest to most involved).

## Technical Context

**Language/Version**: Markdown (README.md only) - no code, Nix module, or
package changes.

**Primary Dependencies**: None new. Documents existing, already-verified
mechanisms (`home/git.nix`, `home/secrets.nix`'s `workspacesHost.secrets`,
`home/direnv.nix`, `pkgs/pgpass`, `pkgs/workspaces-host-update`).

**Testing**: Full read-through against the acceptance scenarios; grep for
forbidden origin-story terms; the documented `sed` command run against
the actual `home/git.nix` to confirm its exact before/after diff, rather
than trusting the string literals from memory.

**Constraints**: Must not change what any documented mechanism actually
does - only how it's explained and in what order. No build/activation
verification needed (no code changed), but the one CLI command the new
section teaches (the `sed` line) is run for real against this repo's
actual file, not just visually inspected.

## Constitution Check

- **Principle I**: N/A - no flake inputs touched.
- **Principle V**: Single feature, single PR (documentation only).

No violations.

## Project Structure

```text
README.md   # full rewrite: intro, "What you get", Roadmap wording,
            # Installation (WSL-first, single-user, Linux/macOS as
            # deltas), new "Updating your Git identity, and other
            # secrets, from the CLI" section, and origin-story language
            # removed throughout every other section
```
