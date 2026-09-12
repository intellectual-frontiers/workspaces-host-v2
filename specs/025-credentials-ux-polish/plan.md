# Implementation Plan: Credentials UX Polish

**Branch**: `025-credentials-ux-polish` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Add a credentials-file bootstrap step to `install.sh` (copy
`credentials.example` to `~/.config/workspaces-host/credentials` at mode
600 if it doesn't exist yet), mirroring what `workspaces-host-update`
already does on its own first run. Reorder the README so "Setting up
your credentials" (and its subsections) comes immediately after
"Installation" instead of deep in the document, fixing every
cross-reference this reordering affects. Add a new subsection
explaining the `${VAR:-$(cat .../secrets/env/VAR)}` `.envrc` pattern for
code that runs both locally and in CI/CD or a container.

## Technical Context

**Language/Version**: POSIX `/bin/sh` (`install.sh`), Markdown
(README.md).

**Primary Dependencies**: None new.

**Testing**:
- `install.sh`'s new step tested in isolation against a fresh `$HOME`
  (creates the file at mode 600, matching the template) and against an
  existing file (left untouched, including a deliberately modified
  value used as a canary).
- The `.envrc` pattern's core claim - that `${VAR:-$(cmd)}` never
  evaluates `cmd` when `VAR` is already set - verified directly: a
  marker file the fallback command would create is confirmed absent
  when the variable is pre-set, and present when it isn't.
- Every "above"/"below" cross-reference touching or pointing at the
  moved section read by hand after reordering.

**Constraints**: The README reorder must not change the moved content
itself (verified via line-count-preserving reassembly, not a rewrite),
only its position and the directional wording of cross-references.

## Constitution Check

- **Principle I**: no new flake inputs; no Nix module touched at all.
- **Principle V**: scoped as its own spec/PR, on top of already-merged
  feature 024.

No violations.

## Project Structure

```text
install.sh   # updated: new step 5 creates the credentials file; renumbered step 6
README.md    # reordered: "Setting up your credentials" moved after Installation;
             # updated: Windows/Other-platforms/manual-steps wording; new
             # ".envrc" CI/CD-vs-local subsection; fixed cross-references
```
