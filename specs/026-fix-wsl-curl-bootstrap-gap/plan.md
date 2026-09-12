# Implementation Plan: Fix the curl Bootstrap Gap on Fresh WSL Debian

**Branch**: `026-fix-wsl-curl-bootstrap-gap` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Prefix the README's documented Windows/WSL bootstrap command with
`sudo apt-get update && sudo apt-get install -y curl git &&` so it
actually works on a fresh, genuinely minimal WSL Debian image (confirmed
by the user to lack `curl`), rather than assuming `curl` already exists
to fetch `install.sh` in the first place. Correct "Other platforms" to
stop claiming the identical command works unchanged across every
platform - it now distinguishes Linux (check for `curl`, install with
the right package manager first if missing) from macOS (always has
`curl`, never needs a prefix).

## Technical Context

**Language/Version**: Markdown (README.md only) - no `install.sh` code
change; its own internal prerequisite logic was already correct.

**Testing**: The new chained command verified syntax-valid under both
`sh -n` and `dash -n`; confirmed no other stale copy of the old
unprefixed one-liner remains in the README.

**Constraints**: Must not suggest a Debian-specific `apt-get` prefix for
macOS, which has neither the gap nor the tool.

## Constitution Check

- **Principle I**: no flake/code changes.
- **Principle V**: scoped as its own spec/PR - a direct bug fix, not
  bundled with unrelated work.

No violations.

## Project Structure

```text
README.md   # updated: Windows/WSL step 4's bootstrap command; "Other platforms" per-platform guidance
```
