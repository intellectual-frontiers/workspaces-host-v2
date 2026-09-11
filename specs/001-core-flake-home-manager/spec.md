# Feature Specification: Core Flake + Home-Manager Module

**Feature Branch**: `001-core-flake-home-manager`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Core flake: flake.nix plus a home-manager module covering fish shell, oh-my-posh prompt, direnv/nix-direnv, git config templating, and the core CLI toolset including ported git helper scripts (semtag, mgitstatus, git-standup), replacing chezmoi+Homebrew+pkgx+eget+mise+SDKMAN as the single reproducibility engine"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reproducible shell environment from a clean checkout (Priority: P1)

An engineer clones this repository onto a fresh machine (WSL2, Linux, or
macOS) that already has Nix installed, runs a single provisioning command,
and gets a fully configured interactive shell: Fish as the default shell,
the oh-my-posh prompt themed and working, direnv wired into Fish via
nix-direnv, and their git identity/aliases configured — with no manual
follow-up steps.

**Why this priority**: This is the MVP this whole rewrite exists to prove:
that a declarative flake can replace the old chezmoi+Homebrew bootstrap.
Nothing else in the roadmap (containers, agent scaffolding, secrets) is
worth building on top of a core that doesn't work.

**Independent Test**: On a clean checkout with only Nix installed, run
`home-manager switch --flake .#<profile>` and confirm: `fish` is the login
shell, `oh-my-posh` renders a themed prompt, `direnv status` reports
nix-direnv as the active implementation, and `git config --get user.name`
/ `user.email` resolve to the values supplied via flake input/config.

**Acceptance Scenarios**:

1. **Given** a clean checkout of this repository on a machine with only Nix
   (with flakes enabled) installed, **When** the engineer runs
   `home-manager switch --flake .#default`, **Then** the command completes
   without error and a new shell opens as Fish with the oh-my-posh prompt
   visible.
2. **Given** a home-manager generation has already been applied, **When**
   the engineer runs `home-manager switch --flake .#default` again with no
   changes to the flake, **Then** the command is a no-op (idempotent) and
   exits successfully.
3. **Given** the module is applied, **When** the engineer `cd`s into a
   directory containing an `.envrc`, **Then** direnv (via nix-direnv)
   loads that directory's environment automatically without a manual
   `direnv allow` beyond the first-time trust prompt.

---

### User Story 2 - Git identity and aliases configured declaratively (Priority: P2)

An engineer's git identity (name, email, signing key), common aliases, and
sane defaults (pull.rebase, init.defaultBranch, etc.) are generated from a
declarative home-manager option rather than a hand-edited `~/.gitconfig` or
a chezmoi Go-template — equivalent to the old repo's `dot_gitconfig.tmpl`,
but expressed as Nix config instead of templated text.

**Why this priority**: Git configuration was the concrete example of
"templated dotfile" behavior in the old repo that this rewrite must prove
it can replace declaratively; it's also a prerequisite for the ported git
helper scripts in User Story 3.

**Independent Test**: Set the module's git-identity options in a test
profile, apply it, and confirm the resulting `~/.gitconfig` contains the
expected `[user]`, `[alias]`, and default sections with no manual editing.

**Acceptance Scenarios**:

1. **Given** `programs.git.userName` / `userEmail`-equivalent options are
   set in the flake's home-manager configuration, **When** the
   configuration is applied, **Then** `git config --get user.name` and
   `git config --get user.email` return exactly those values.
2. **Given** the module is applied, **When** the engineer inspects
   `~/.gitconfig`, **Then** it is a generated file (not hand-edited) whose
   content changes only when the flake configuration changes.

---

### User Story 3 - Small git helper scripts available on PATH (Priority: P3)

An engineer has `semtag`, `mgitstatus`, and `git-standup` available on
`PATH` after applying the configuration, packaged as flake outputs rather
than installed via Homebrew formulas or manually cloned scripts.

**Why this priority**: These are the "small sharp git helper scripts"
called out as worth carrying over conceptually from the old repo. They are
useful but not required for the core shell/prompt/direnv/git MVP to be
considered done, so they are the lowest priority of the three stories.

**Independent Test**: After applying the configuration, run `semtag`,
`mgitstatus`, and `git-standup --help` (or equivalent) from a shell and
confirm each resolves on `PATH` and runs without error.

**Acceptance Scenarios**:

1. **Given** the home-manager configuration has been applied, **When** the
   engineer runs `which semtag mgitstatus git-standup`, **Then** all three
   resolve to paths under the Nix store (not a system package manager
   path).
2. **Given** one of these tools is invoked inside a git repository,
   **When** it runs, **Then** it behaves equivalently to its behavior in
   the old repo (e.g. `git-standup` lists the user's commits from the last
   working day; `mgitstatus` reports status across multiple repos under a
   directory; `semtag` computes/applies the next semantic version tag).

---

### Edge Cases

- What happens when Nix itself is not yet installed on the target machine?
  (Out of scope for this feature: this spec assumes Nix + flakes are
  already available. Bootstrapping Nix itself, if needed, is a separate
  concern from this feature.)
- What happens when a machine has an existing, unmanaged `~/.gitconfig` or
  `~/.config/fish/config.fish` before the module is first applied?
  Home-manager's standard backup-existing-file behavior applies; this
  feature does not need to invent a different migration path.
- What happens on macOS vs. Linux vs. WSL2 — do all three activate the
  same home-manager profile? This feature targets Linux/WSL2 and macOS
  parity for the core module; platform-specific option branching (if any)
  must be documented in the flake, not silently divergent behavior.
- What happens if `home-manager switch` is interrupted partway through?
  Home-manager generations are atomic; a partial activation must not leave
  the shell config in an inconsistent state (this is a property of
  home-manager itself, which this feature relies on rather than reimplements).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST provide a `flake.nix` at its root that
  defines at least one home-manager configuration output (e.g.
  `homeConfigurations.default`) buildable with `home-manager switch --flake .#<name>`.
- **FR-002**: The flake MUST pin all inputs (nixpkgs, home-manager, and any
  other flake inputs) via `flake.lock`, such that two applications of the
  same commit on different machines produce the same closure.
- **FR-003**: The home-manager configuration MUST set Fish as the
  configured interactive shell, with a home-manager-managed `config.fish`
  (no manually-maintained dotfile outside the module).
- **FR-004**: The home-manager configuration MUST install and configure
  oh-my-posh with a checked-in theme (or a documented default theme),
  wired into the Fish prompt.
- **FR-005**: The home-manager configuration MUST enable direnv with the
  nix-direnv extension, integrated with Fish so per-directory `.envrc`
  files load automatically after the standard direnv trust step.
- **FR-006**: The home-manager configuration MUST expose declarative
  options for git identity (user name, user email, and optionally a
  signing key) and MUST render a generated `~/.gitconfig` from those
  options, including a documented set of default aliases and
  safe-default settings (e.g. `init.defaultBranch`, `pull.rebase`).
- **FR-007**: The flake MUST package `semtag`, `mgitstatus`, and
  `git-standup` as flake outputs (derivations) and include them in the
  home-manager configuration's installed packages, such that they resolve
  on `PATH` after activation.
- **FR-008**: The flake MUST NOT depend on Homebrew, pkgx, eget, mise,
  SDKMAN!, or chezmoi at any point in provisioning — Nix + home-manager is
  the sole reproducibility engine for everything this feature covers.
- **FR-009**: `nix flake check` MUST pass against the flake with no
  errors, as the baseline automated verification for this feature (a full
  CI wiring of this check is Phase 7's concern; this feature only needs
  the check itself to be meaningful and passing).
- **FR-010**: The flake MUST support both Linux (including WSL2) and
  macOS as evaluation/build targets for the home-manager configuration
  (e.g. via `flake-utils` or an equivalent `eachDefaultSystem` pattern),
  even if only Linux is exercised in this environment's CI.

### Key Entities

- **Home-manager profile**: A named `homeConfigurations` output (e.g.
  `default`) bundling the Fish/oh-my-posh/direnv/git configuration and the
  core CLI toolset for one target user/machine class.
- **Git identity options**: The set of declarative options (name, email,
  signing key) a profile supplies to the git-config-generation module.
- **Ported git helper script**: One of `semtag`, `mgitstatus`,
  `git-standup` — a flake-packaged derivation exposing the same behavior
  the old repo's Homebrew-installed/manually-cloned version had.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A clean checkout on a machine with only Nix installed reaches
  a fully working shell (Fish + oh-my-posh + direnv + git identity) via a
  single `home-manager switch --flake .#default` command, with zero manual
  post-steps.
- **SC-002**: Running `home-manager switch --flake .#default` twice in a
  row with no configuration changes is idempotent (second run reports no
  changes / succeeds trivially).
- **SC-003**: `nix flake check` passes with zero errors on every commit
  that lands on `main` for this feature.
- **SC-004**: All three ported git helper scripts (`semtag`, `mgitstatus`,
  `git-standup`) are resolvable on `PATH` and runnable immediately after
  activation, with no separate install step beyond the flake apply.

## Assumptions

- Nix (with flakes and `nix-command` experimental features enabled) is
  already installed on the target machine; installing Nix itself is out
  of scope for this feature.
- A single default home-manager profile is sufficient for this feature;
  per-persona profiles (backend/data/mobile/agent-ops) are explicitly
  deferred to Phase 6 (Workspace profiles).
- Container/OCI image builds from these same flake outputs are explicitly
  deferred to Phase 2 (Container/OCI parity) and are not required by this
  feature, though this feature's outputs should not preclude that reuse.
- Secrets management (sops-nix / `op`) is explicitly deferred to Phase 4
  and is out of scope here; git signing-key configuration in this feature
  is limited to referencing a key ID/path, not provisioning the key
  material itself.
- The oh-my-posh theme and exact alias set are implementation details the
  plan may choose sensible defaults for; this spec does not mandate a
  specific theme name or alias list beyond "a documented default exists."
