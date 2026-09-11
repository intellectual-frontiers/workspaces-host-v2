# Feature Specification: Secrets Management

**Feature Branch**: `004-secrets-management`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Secrets: a sops-based home-manager module replacing gopass + .pgpass + manual OneDrive rsync, and sensitivectl generalizing the old coach-sensitivectl backup/restore pattern over rclone remotes"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Declared secrets are decrypted at activation time, never baked into the store (Priority: P1)

An engineer declares a sops-encrypted secret in their home-manager
configuration (`workspacesHost.secrets.<name> = { sopsFile = ...; path =
...; }`), runs `home-manager switch`, and finds the decrypted plaintext at
`$XDG_STATE_HOME/workspaces-host/secrets/<path>` with `0600` permissions -
never inside the world-readable `/nix/store`.

**Why this priority**: This is the entire point of moving off
gopass/`.pgpass`/ad-hoc secret files - if a secret can end up in the Nix
store (readable by every user in a multi-user Nix install, and by
definition immutable/public once built), the module has failed at its one
job, regardless of anything else it does.

**Independent Test**: sops-encrypt a test file with a throwaway age key,
declare it via `workspacesHost.secrets`, run the activation, and confirm
the decrypted plaintext appears at the documented path with `0600`
permissions and the correct content - while `nix store ls` /
`grep -r` across the built activation package's store paths finds no
trace of the plaintext.

**Acceptance Scenarios**:

1. **Given** a `workspacesHost.secrets.token` declaration pointing at a
   sops-encrypted file, and `SOPS_AGE_KEY_FILE` pointing at the matching
   age key, **When** the generated activation script is run, **Then**
   `$XDG_STATE_HOME/workspaces-host/secrets/token` exists with mode `600`
   and its content matches the plaintext.
2. **Given** the same declaration, **When** the activation package itself
   (the built Nix derivation, before running `activate`) is inspected,
   **Then** it contains no decrypted plaintext anywhere in its closure -
   only the still-encrypted sops file (referenced by store path) and the
   decrypt command.
3. **Given** no `workspacesHost.secrets` are declared (the default,
   unmodified profile), **When** `home-manager switch` runs, **Then** no
   `sops`/`age` packages are installed and no activation step runs for
   this module (it's a true no-op, not just an empty one).

---

### User Story 2 - Generalized backup/restore over any rclone remote (Priority: P1)

An engineer configures a named profile (local path + rclone remote) in a
small JSON config and runs `sensitivectl backup <profile>` /
`sensitivectl restore <profile>` - working against whatever rclone remote
type they've configured (S3, a self-hosted WebDAV, another cloud
provider, or even a second local disk), not hardcoded to OneDrive the way
the old repo's `coach-sensitivectl` was.

**Why this priority**: This is the concrete "generalize over rclone
remotes generically" ask from the roadmap, and stands on its own
independent of the sops module.

**Independent Test**: Configure a `local`-type rclone remote (no external
service needed), back up a scratch directory to it, wipe the local
directory, restore, and confirm the content round-trips exactly.

**Acceptance Scenarios**:

1. **Given** a profile `{"local": "<dir>", "remote": "myremote:<path>"}`
   in `sensitivectl.json`, **When** `sensitivectl backup <profile>` runs,
   **Then** the remote path contains an exact copy of the local
   directory's contents.
2. **Given** the same profile, **When** the local directory is deleted
   and `sensitivectl restore <profile>` runs, **Then** the local
   directory is recreated with the exact content that was backed up.
3. **Given** `sensitivectl list`, **When** run, **Then** it prints every
   profile name configured in `sensitivectl.json`.
4. **Given** an unknown profile name, **When** `sensitivectl backup
   nope` runs, **Then** it exits non-zero with a clear error rather than
   running rclone with empty arguments.

---

### Edge Cases

- What happens if the age/PGP key `sops` needs isn't available at
  activation time? `sops --decrypt` fails with its own clear error and
  the activation script exits non-zero (via `set -eu` in the activation
  fragment) - the engineer fixes their key setup and re-runs
  `home-manager switch`. This module does not swallow or paper over that
  failure.
- What happens on a second `home-manager switch` with the same secret
  declaration? The file is decrypted again (sops re-run unconditionally)
  - idempotent by virtue of always producing the same plaintext from the
  same encrypted input, not by skipping work.
- Why not manage gopass or `.pgpass` directly as a compatibility shim?
  Because the roadmap's intent is replacement, not emulation - projects
  needing a password-manager-style secret store use `sops` (declarative,
  git-friendly, keyed by the same age/PGP keys this module already
  expects) instead.
- What happens if `sensitivectl`'s config file doesn't exist at all?
  Every subcommand except `--help` fails with a clear "no config at
  \<path\>" error rather than a confusing rclone or `jq` failure.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The home-manager module MUST expose a
  `workspacesHost.secrets` option: an attribute set of `{ sopsFile, path
  }` entries.
- **FR-002**: For each declared secret, the module MUST decrypt
  `sopsFile` at **activation** time (not build/eval time) into
  `$XDG_STATE_HOME/workspaces-host/secrets/<path>`, creating parent
  directories as needed, with the secrets directory at mode `700` and
  each decrypted file at mode `600`.
- **FR-003**: The module MUST NOT write decrypted plaintext into any
  location that becomes part of a Nix store path.
- **FR-004**: When `workspacesHost.secrets` is empty (the default), the
  module MUST add no packages and register no activation step.
- **FR-005**: The module MUST NOT manage or provision decryption key
  material (age/PGP keys) itself - that remains a deliberate, separate
  step the engineer performs out-of-band, consistent with Constitution
  Principle III.
- **FR-006**: The flake MUST provide a `sensitivectl` command
  (`packages.<system>.sensitivectl`, included in `home.packages`) with
  `list`, `backup <profile>`, and `restore <profile>` subcommands, driven
  by a JSON config at `$SENSITIVECTL_CONFIG` (default:
  `~/.config/workspaces-host/sensitivectl.json`).
- **FR-007**: `sensitivectl backup`/`restore` MUST work against any
  `rclone`-supported remote type - the tool itself must not hardcode
  OneDrive, or any other specific provider.
- **FR-008**: `sensitivectl` MUST pass through any arguments after `--`
  directly to the underlying `rclone sync` invocation (e.g. `--dry-run`,
  `--exclude`).

### Key Entities

- **Declared secret**: one `workspacesHost.secrets.<name>` entry - a sops
  file plus its decrypted-output path.
- **sensitivectl profile**: a named `{ local, remote }` pair in
  `sensitivectl.json`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A sops-encrypted secret declared via `workspacesHost.secrets`
  is decrypted to the correct plaintext at the documented path with `600`
  permissions after activation, verified against a real (throwaway) age
  key and sops-encrypted file.
- **SC-002**: `sensitivectl backup` followed by a local-directory wipe and
  `sensitivectl restore` reproduces the original content exactly, verified
  against a real local-type rclone remote.
- **SC-003**: The default profile (no secrets declared) shows zero
  behavior change from Phase 3 - no new packages, no new activation
  steps - confirmed by diffing `home.packages` before/after this feature
  with `workspacesHost.secrets` left unset.
- **SC-004**: `nix flake check --all-systems` continues to pass with
  `sensitivectl` added for all four systems.

## Assumptions

- `sops` and `age` are the chosen secrets backend (over 1Password's `op`
  CLI, the roadmap's other named option) because they need no external
  service/account and are fully offline-verifiable, which matters for
  this feature's own test suite as much as for engineers' daily use;
  nothing here precludes a later `op`-based module living alongside this
  one.
- Key provisioning (getting an age or PGP private key onto a machine in
  the first place) is out of scope - this feature assumes the key is
  already present wherever `sops --decrypt` runs, exactly as upstream
  `sops` itself assumes.
- `sensitivectl`'s JSON config is per-machine, human-edited state (like
  `~/.gitconfig` before Phase 1) - it is not itself declared through
  home-manager, since the local paths and remote names it references are
  inherently machine-specific.
