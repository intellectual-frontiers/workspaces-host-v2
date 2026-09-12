# Feature Specification: Scope AI Harness Credentials Per-Invocation

**Feature Branch**: `023-scope-ai-harness-credentials`

**Created**: 2026-09-12

**Status**: Draft

**Input**: Discovered while auditing the repository against its own
constitution and against native Nix/home-manager idioms, at the user's
request ("check to see if there are any of my requirements for this
repo that conflict with how Nix works by default... point those out
along with solutions").

## Background

Feature 022 (AI harness credentials) added a `path = "env/VARNAME"`
convention that decrypted a secret and auto-exported it, via
`set -gx`, into **every interactive fish shell** - so any process
started from that shell, not just the AI CLI it was meant for, could
read it.

That directly contradicts this repository's own
[constitution](../../.specify/memory/constitution.md), Principle III
("Secrets Never Touch the Agent's Shell Unscoped"), which is explicit
and marked non-negotiable: secrets "MUST be resolved through a scoped
secrets tool... at the point of use, never exported as ambient
environment variables available to an entire shell session or to an AI
coding agent's unscoped process tree... This is non-negotiable given
this repository's explicit purpose of provisioning environments that AI
coding agents operate inside." Feature 022 built exactly the pattern
this principle rules out, for exactly the class of tool (an AI coding
agent's process tree) the principle calls out by name.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - An AI CLI's key never leaks into the rest of the shell (Priority: P1)

An engineer configures `ANTHROPIC_API_KEY` for Claude Code. Every other
program they run in that same terminal - a build script, `psql`, an
unrelated one-off `curl` - must never see that value, only `claude`
itself.

**Independent Test**: Configure the secret, open an interactive shell,
confirm `echo $ANTHROPIC_API_KEY` is empty, then confirm running `claude`
(or a stand-in executable of that name, for testing without a real
network call) sees the correct value.

**Acceptance Scenarios**:

1. **Given** `workspacesHost.secrets.anthropic-key = { path =
   "env/ANTHROPIC_API_KEY"; ...};` declared and activated, **When** a new
   interactive shell opens, **Then** `$ANTHROPIC_API_KEY` is unset in
   that shell.
2. **Given** the same setup, **When** the engineer runs `claude ...`,
   **Then** the real `claude` binary (found via `command claude`,
   bypassing the wrapper) receives `$ANTHROPIC_API_KEY` set to the
   decrypted value for that invocation only.
3. **Given** no matching secret is configured, **When** the engineer
   runs `claude`/`codex`/`gemini`/`aider`, **Then** it behaves exactly as
   if no wrapper existed (a transparent pass-through to `command <cli>
   $argv`), so the CLI's own `login` flow is unaffected.

---

### Edge Cases

- `aider` accepts any of four possible variable names (whichever
  provider's key is configured) - the wrapper checks each of
  `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`,
  `GOOGLE_API_KEY` in turn and sets whichever decrypted files exist; more
  than one may be set simultaneously (matches how `aider` itself already
  picks a provider based on which key is present).
- The wrapper mechanism is fish-specific (`programs.fish.functions`) -
  a script or another shell invoking `claude` directly without going
  through an interactive fish session won't get the auto-injection.
  Consistent with this repository's existing fish-first design (the
  GitHub-token pattern is likewise scoped through fish/direnv, not a
  shell-agnostic mechanism); a non-fish/non-interactive caller can
  export the variable itself or add a `.envrc`, same as any other
  secret this repo's README documents.
- `doctor`'s credential check previously read `$VARNAME` directly, which
  is now correctly almost-always unset by design - it was updated to
  additionally check for the decrypted secret *file* the wrapper reads,
  so a properly-configured credential still reports `PASS` even though
  no ambient variable exists to check.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/shell.nix` MUST NOT export any `workspacesHost.secrets`
  value into the ambient interactive-shell environment.
- **FR-002**: `home/ai-harness.nix` MUST define a `programs.fish.functions`
  wrapper for `claude`, `codex`, `gemini`, and `aider`, each of which:
  sets its known credential variable(s), via fish's function-scoped
  `set -lx`, only for its own invocation of the real binary (`command
  <name> $argv`); and is a no-op pass-through when no matching secret
  file exists.
- **FR-003**: `pkgs/doctor/doctor`'s AI-harness credential check MUST
  treat either an already-set environment variable OR the existence of
  the matching decrypted secret file as "configured."
- **FR-004**: README's "Setting up AI harness credentials" section MUST
  describe the corrected, per-invocation-scoped behavior, not shell-wide
  export.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.current.activationPackage
  --impure` succeeds with the updated `home/ai-harness.nix` and
  `home/shell.nix`.
- **SC-002**: Real verification, not just a successful build: with a
  fake secret configured, `fish -i -c 'echo $ANTHROPIC_API_KEY'` prints
  nothing, while a stand-in `claude` executable's own echo of
  `$ANTHROPIC_API_KEY`, run through the wrapper, prints the real
  decrypted value.
- **SC-003**: `doctor` reports the configured credential as available
  even though it is no longer an ambient variable.
- **SC-004**: `nix flake check --all-systems` continues to pass.

## Assumptions

- This is a correction to already-merged feature 022, scoped as its own
  independent spec per Constitution Principle V rather than amending
  022's history.
- The GitHub-token pattern (`path` without an `env/` prefix, scoped via
  a project's own `.envrc`) was already constitutionally compliant and
  is unchanged by this feature.
