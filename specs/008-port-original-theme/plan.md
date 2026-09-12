# Implementation Plan: Port the Original oh-my-posh Theme

**Branch**: `008-port-original-theme` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Replace `themes/oh-my-posh/default.omp.json` with a byte-identical copy of
`strategy-coach/workspaces-host`'s `dot_config/oh-my-posh/coach.omp.json`,
renamed `themes/oh-my-posh/coach.omp.json` to preserve the original's own
name; update `home/shell.nix`'s `readFile` reference accordingly.

## Technical Context

**Language/Version**: JSON (theme file, unchanged schema v3 - oh-my-posh
23.20.3, already pinned by this flake, parses it without issue).

**Primary Dependencies**: None new.

**Testing**: Byte-diff against the original file; real activation +
`oh-my-posh print primary` against the generated config, including a
dirty-working-tree case to confirm the theme's conditional git-segment
coloring still works.

**Constraints**: The copy must be exact - no reformatting, no re-indentation,
no substituting equivalent-but-different JSON encodings by hand (Nix's own
JSON round-trip through `programs.oh-my-posh.settings` already re-encodes
`\uXXXX` escapes as raw UTF-8, which is expected and is not something this
feature works around, per spec FR-003 / Edge Cases).

## Constitution Check

- **Principle I**: No new inputs; this is a pinned, checked-in file.
- **Principle IV**: N/A directly - a prompt theme has no container/host
  parity dimension.
- **Principle V**: Single small fix, single PR.

No violations.

## Project Structure

```text
themes/oh-my-posh/coach.omp.json   # replaces default.omp.json
home/shell.nix                      # updated readFile path
```
