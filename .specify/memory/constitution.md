# Workspaces Host v2 Constitution

## Core Principles

### I. Reproducible by Lockfile, Not by Drift
Every tool, package, and shell configuration this project provisions MUST be
pinned by a lockfile (`flake.lock`) rather than resolved at install time
against a mutable upstream (a rolling Homebrew formula, an untracked `mise`
version, a `chezmoi apply` that mutates whatever state a host happens to be
in). A fresh `nix develop` or `home-manager switch` against a given commit
MUST produce a byte-for-byte identical closure on any machine, any day.
Imperative "install this, then patch that" bootstrapping is prohibited;
if a tool cannot be expressed declaratively in the flake, it does not belong
in this repository until it can.

### II. Ephemeral and Disposable by Default
Sandboxes provisioned from this repository are treated as disposable:
destroy and rebuild rather than patch in place, and never assume prior
state survives a rebuild. Every feature MUST be designed so that
`home-manager switch` (or the equivalent container/image build) from a
clean checkout produces a fully working environment with no manual
recovery steps. Anything that would make an environment un-reproducible
if wiped — an untracked local edit, a manually-run one-off command, state
that lives only on a WSL host and nowhere else — is a defect to be fixed,
not a workaround to be documented.

### III. Secrets Never Touch the Agent's Shell Unscoped
Secrets (API keys, tokens, credentials) MUST be resolved through a scoped
secrets tool (e.g. `sops-nix`, `op`) at the point of use, never exported
as ambient environment variables available to an entire shell session or
to an AI coding agent's unscoped process tree. Per-project secret scoping
(direnv-style) is required wherever a secret is needed; a feature that
widens secret exposure beyond the project or command that needs it MUST be
rejected in review. This is non-negotiable given this repository's explicit
purpose of provisioning environments that AI coding agents operate inside.

### IV. Container and Cloud-Harness Parity is Required, Not Optional
WSL2/Linux/macOS hosts are one provisioning target among several — a
container image and a cloud agent-harness session are equally first-class
targets, built from the same flake outputs. A feature that only works on
a persistent WSL host, or that cannot be built as an OCI image from the
same closure, is incomplete. "Works in my sandbox" without a corresponding
container build is not a passing state for any feature in this repository.

### V. Small Independent Specs, No Monolithic Rewrites
Each roadmap phase (and each meaningfully separable piece of a phase) is
its own Spec Kit feature: its own spec, plan, tasks, and pull request.
Big-bang commits that bundle multiple unrelated concerns are prohibited.
A phase that is too large to review as a single PR MUST be split into
smaller specs before implementation begins, even if that means a phase
spans several PRs merged in sequence.

## Additional Constraints

- **Toolchain**: Nix flakes + home-manager are the single reproducibility
  engine for this repository. Homebrew, pkgx, eget, mise, SDKMAN!, and
  chezmoi — the previous generation's toolchain — are not to be
  reintroduced; where the old repository used one of them, the
  replacement is a flake input or home-manager module, not a port of the
  original tool.
- **Shell UX**: bash is the default interactive shell (amended
  2026-09-13; fish originally) - chosen so nothing copy-pasted from
  elsewhere ever needs translating, at the deliberate cost of needing
  extra tooling (`ble.sh`, `fzf`, `zoxide`) layered on top for the
  interactive conveniences fish had natively. oh-my-posh remains the
  prompt, and everything here (bash config, the added tooling, the
  prompt) is configured via home-manager rather than dotfile templating.
- **Per-project env scoping**: direnv with `nix-direnv` is the standard
  mechanism for project-local environment and secret scoping.
- **OCI builds**: container images are built from the same flake outputs
  as the host environment (via `nix2container` or `dockerTools`), never
  from a hand-maintained Dockerfile that could drift from the flake.

## Development Workflow

- Every feature phase on the roadmap follows the Spec Kit lifecycle:
  `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` →
  `/speckit-implement`, each producing its own PR against `main`.
  `/speckit-clarify`, `/speckit-analyze`, and `/speckit-checklist` are used
  where they reduce ambiguity or risk, at the implementer's discretion.
- A PR is not ready for review until its feature's stated verification
  step passes locally (e.g. `nix flake check`, `home-manager switch`
  succeeding, or the equivalent for that phase).
- CI (once Phase 7 lands) enforces `nix flake check` and the OCI build on
  every PR; until then, the author is responsible for running the
  equivalent checks locally and recording the result in the PR
  description.

## Governance

This constitution supersedes ad-hoc practice for this repository. Any PR
that conflicts with a principle above must either be changed to comply or
must amend this constitution explicitly, with the reasoning recorded in
the amending PR's description. Complexity that cannot be justified against
these principles (in particular Principles I, II, and V) is grounds for
requesting changes in review.

**Version**: 1.1.0 | **Ratified**: 2026-09-11 | **Last Amended**: 2026-09-13
