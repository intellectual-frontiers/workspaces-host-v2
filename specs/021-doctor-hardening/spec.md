# Feature Specification: Doctor Hardening for Credentials & Beginner Pitfalls

**Feature Branch**: `021-doctor-hardening`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "In the doctor script be sure to add checks for whether or not GitHub, GitLab and other secrets have been setup properly and other checks for things that can go wrong because of young inexperienced devs." Follow-up: "doctor-check list above is the right start but feel free to add more things that young or inexperienced Linux people get wrong."

## Background

`doctor` checked tool presence and a handful of config files, but had no
way to tell an engineer whether their GitHub/GitLab credentials actually
work (as opposed to a token file merely existing), and covered none of
the classic first-time Linux/WSL mistakes: SSH key permissions, working
under WSL's slow `/mnt/c` Windows filesystem, disk space, locale
misconfiguration, a plaintext `.netrc`, an overly permissive `umask`, or
needing `sudo` for every `docker` command.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Doctor confirms GitHub/GitLab credentials actually work (Priority: P1)

An engineer runs `doctor` and finds out, definitively, whether `gh`/`glab`
are actually authenticated - not just installed.

**Independent Test**: Run `doctor` with `gh`/`glab` installed but not
logged in; confirm both are reported as un-authenticated with a concrete
next step. Log in to one; confirm it flips to authenticated.

**Acceptance Scenarios**:

1. **Given** `gh`/`glab` installed and not authenticated, **When**
   `doctor` runs, **Then** each reports a `WARN` naming the exact login
   command.
2. **Given** either is authenticated, **When** `doctor` runs, **Then**
   it reports `PASS` for that tool.

---

### User Story 2 - Doctor catches common first-time Linux/WSL mistakes (Priority: P1)

An engineer new to Linux/WSL gets concrete, actionable warnings for the
mistakes that actually bite beginners, before they turn into a confusing
failure somewhere else (a git push that silently uses the wrong
credentials, an `ssh` connection refused with no clear reason, a build
that's mysteriously slow because it's running against `/mnt/c`).

**Independent Test**: Exercise each new check against both its failing
and passing state for real (not just reading the code) and confirm the
reported status flips correctly.

**Acceptance Scenarios**:

1. **Given** `~/.ssh` or a private key with overly permissive mode,
   **When** `doctor` runs, **Then** it reports the exact wrong mode and
   the `chmod` command to fix it; given the correct mode, it passes.
2. **Given** no SSH private key exists at all, **When** `doctor` runs,
   **Then** it suggests `ssh-keygen`.
3. **Given** running inside WSL (`/proc/version` mentions "microsoft")
   with `$HOME` under `/mnt/*`, **When** `doctor` runs, **Then** it warns
   about the slower Windows-filesystem mount; given `$HOME` on the Linux
   filesystem, it passes.
4. **Given** low free disk space on the filesystem holding `$HOME`,
   **When** `doctor` runs, **Then** it warns and suggests
   `nix-collect-garbage -d`.
5. **Given** a misconfigured locale (`locale(1)` reports it cannot set
   `LC_*`), **When** `doctor` runs, **Then** it warns with the fix.
6. **Given** a `~/.netrc` file, **When** `doctor` runs, **Then** it warns
   about plaintext credentials (more urgently if the file's mode isn't
   `600`), pointing at `gh auth login`/the sops+direnv pattern instead.
7. **Given** `umask 000`, **When** `doctor` runs, **Then** it warns that
   new files are world-writable by default.
8. **Given** `docker` installed and the current user not in the `docker`
   group (and not root), **When** `doctor` runs, **Then** it suggests
   `usermod -aG docker`.

---

### Edge Cases

- Every new check must degrade gracefully (no crash, no false
  positive/negative) when its underlying tool (`locale`, `df`, `id`) is
  missing - guarded with `command -v` throughout, matching this file's
  existing style.
- The SSH check's advice (`ssh-keygen`) is only actionable if `ssh`/
  `ssh-keygen` are actually installed - confirmed, during implementation,
  that this repository did not previously provision an SSH client at
  all (a real, standalone gap fixed alongside this feature by adding
  `openssh` to `home/tools.nix`).
- The disk-space check must not error/crash on a non-numeric `df` result
  (guarded with a `case` pattern rejecting anything but pure digits
  before doing arithmetic).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/tools.nix` MUST install `gh`, `glab`, and `openssh`.
- **FR-002**: `pkgs/doctor/doctor` MUST report `gh auth status`/
  `glab auth status` results (not just PATH presence) for whichever of
  the two are installed.
- **FR-003**: `pkgs/doctor/doctor` MUST check: `~/.ssh` and any private
  key's permissions (and warn if no key exists at all); whether `$HOME`
  is under `/mnt/*` while running inside WSL; free disk space on the
  filesystem holding `$HOME`; whether `locale(1)` reports a
  configuration error; `~/.netrc`'s existence and permissions; whether
  `umask` is fully open (`000`); and, if `docker` is installed, whether
  the current user is in the `docker` group (or is root).
- **FR-004**: Every new check MUST be verified against both its passing
  and failing state for real, not inferred from reading the shell code.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.current.activationPackage
  --impure` succeeds with `gh`/`glab`/`openssh` included.
- **SC-002**: Every new check's both states (pass and warn) were
  exercised for real in this project's own dev sandbox: an
  intentionally-wrong-permission SSH key flips from `WARN` to `PASS`
  after `chmod`; `umask 000` triggers the warning; a `.netrc` with wrong
  permissions triggers the stronger warning.
- **SC-003**: `nix flake check --all-systems` continues to pass.

## Assumptions

- AI-harness credential setup (Claude Code, Codex, etc.) is deliberately
  out of scope here - it's its own, larger feature (see
  `specs/022-ai-harness-credentials`), not folded into this general
  doctor-hardening pass.
- The specific thresholds chosen (2 GiB free disk space, `umask 000`
  specifically rather than every non-`022` value) are conservative,
  chosen to avoid false positives on reasonable variations rather than
  to catch every possible misconfiguration.
