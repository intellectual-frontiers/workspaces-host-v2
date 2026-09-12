# Feature Specification: AI Harness Credentials

**Feature Branch**: `022-ai-harness-credentials`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "We also need an opinionated, safe, way to
setup AI harness keys so that the AI harnesses and CLIs can be used to
help configure the sandbox after install." Follow-up: "Add Codex AI CLI
as well as any other widely used AI CLIs including any super popular
packages which do similar work."

## Background

An engineer who just ran the one-step installer (feature 020) has a
working sandbox but no AI harness to help configure the rest of it -
`local.nix`, secrets, project setup. This repo already has a safe secrets
mechanism (`workspacesHost.secrets`, feature 004/019) and an
outside-the-repo customization point (`local.nix`, feature 019); this
feature provisions the AI CLIs themselves and gives them an opinionated,
safe way to get an API key, reusing that existing mechanism rather than
inventing a new one.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - AI CLIs are available after install (Priority: P1)

An engineer wants to use Claude Code, OpenAI's Codex CLI, Google's
Gemini CLI, or `aider` right after provisioning, without figuring out
Node.js versions or install commands themselves.

**Independent Test**: Activate the profile; confirm `node`/`npm` and
`aider` are on `PATH`; confirm README documents the exact `npm install
-g` command for each hosted CLI (verified against the real npm registry,
not assumed from training data).

**Acceptance Scenarios**:

1. **Given** a freshly activated profile, **When** the engineer runs
   `aider --version`, **Then** it works with no further install step.
2. **Given** the same profile, **When** the engineer follows README's
   documented command for Claude Code/Codex/Gemini CLI, **Then** the
   install succeeds because the package name and provided binary name are
   correct.

---

### User Story 2 - A safe, opinionated way to set each CLI's API key (Priority: P1)

An engineer needs to give an AI CLI a real API key without ever putting
it in a tracked file or a project-specific `.envrc` (an AI harness needs
its key everywhere, not just in one project).

**Independent Test**: Encrypt a fake key with `sops`, declare it in
`local.nix` with a `path` under `env/`, rebuild/activate, open a new
shell, and confirm the corresponding environment variable is set to the
real decrypted value - not the sops wrapper document.

**Acceptance Scenarios**:

1. **Given** a secret declared with `path = "env/ANTHROPIC_API_KEY"`,
   **When** the profile is activated and a new interactive shell opens,
   **Then** `$ANTHROPIC_API_KEY` is set to the exact plaintext value.
2. **Given** a secret declared WITHOUT the `env/` prefix (the existing
   GitHub-token convention), **When** a new shell opens, **Then** it is
   NOT auto-exported (unchanged, per-project-via-direnv behavior).
3. **Given** no `env/`-prefixed secrets declared, **When** a shell opens,
   **Then** the auto-export loop does nothing (no error, no stray
   variables).

---

### Edge Cases

- **A real, previously-shipped bug found while building this feature**:
  `sops --decrypt` on a file produced by `echo -n "value" | sops
  --encrypt ... /dev/stdin` (the exact pattern this repo's own README
  already documented for the GitHub-token secret, feature 004/014/016)
  returns the *whole wrapper document* (`data: value`), not the bare
  value - caught only because this feature's own verification inspected
  actual decrypted file content instead of trusting `sops --decrypt` not
  to error. Fixed in `home/secrets.nix` with a new `extractKey` option
  (default `"data"`, the key `sops` wraps bare stdin input under;
  settable to `null` for a deliberately multi-key encrypted file) rather
  than changing the encrypt-side convention, so every existing secret
  declaration keeps working unmodified.
- `sops --encrypt`'s default output format is JSON; a file saved with a
  `.yaml` extension needs `--output-type yaml` or a later `--decrypt`
  fails to parse it (`Error unmarshalling input yaml`) - all documented
  encrypt commands (README, `specs/004`'s quickstart) now include it.
- The auto-export loop in `home/shell.nix` only runs inside
  `interactiveShellInit`'s `status is-interactive` guard, same as the
  existing daily-sync-nudge code it sits next to - verified with `fish -i
  -c` (not plain `fish -c`, which does not set `is-interactive`).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `home/ai-harness.nix` (new module, imported by
  `home/default.nix`) MUST install `nodejs` and `aider-chat`.
- **FR-002**: README MUST document the verified `npm install -g` command
  and provided binary name for Claude Code (`@anthropic-ai/claude-code`
  → `claude`), OpenAI Codex CLI (`@openai/codex` → `codex`), and Gemini
  CLI (`@google/gemini-cli` → `gemini`), plus `gh extension install
  github/gh-copilot` for GitHub Copilot CLI - none hand-packaged in this
  flake's pinned nixpkgs, on purpose (near-weekly upstream releases would
  mean either a permanently stale pin or re-deriving an npm hash on every
  release).
- **FR-003**: `home/secrets.nix`'s `secretModule` MUST support
  extracting a named key from the decrypted document (`extractKey`,
  default `"data"`, nullable) so the existing bare-value secret
  convention actually produces the bare value.
- **FR-004**: `home/shell.nix` MUST auto-export, into every interactive
  shell, every declared secret whose `path` starts with `env/`, named
  after the file; secrets without that prefix MUST NOT be auto-exported
  (unchanged from before this feature).
- **FR-005**: `pkgs/doctor/doctor` MUST report, for each of Claude Code,
  Codex, Gemini CLI, and `aider`: whether the CLI is installed, and (if
  installed) whether a known credential env var is set - as a `WARN`,
  not a `FAIL`, since a CLI's own `login` command is an equally valid
  alternative this repo doesn't need to detect.
- **FR-006**: `pkgs/doctor/doctor` MUST report whether the GitHub Copilot
  CLI `gh` extension is installed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `nix build .#homeConfigurations.current.activationPackage
  --impure` succeeds with `home/ai-harness.nix` included.
- **SC-002**: A real encrypt/declare/activate/read cycle (fake key,
  `env/ANTHROPIC_API_KEY`) produces the exact plaintext value in both the
  decrypted state file and a new interactive shell's environment - proof
  the `extractKey` fix actually works, not just that it builds.
- **SC-003**: The pre-existing GitHub-token secret pattern (no `env/`
  prefix) still decrypts to a bare value and still is NOT auto-exported
  into every shell.
- **SC-004**: All three hosted-CLI npm package names are confirmed to
  exist against the real npm registry at implementation time.
- **SC-005**: `nix flake check --all-systems` continues to pass.

## Assumptions

- Hand-packaging Claude Code/Codex/Gemini CLI as Nix derivations is
  deliberately out of scope - their release cadence would make any pin
  stale within days; `nodejs` + documented `npm install -g` is the
  sustainable choice for this repo to maintain.
- `extractKey` defaulting to `"data"` is a behavior change to
  `home/secrets.nix`'s decrypt step for every existing bare-value secret
  declaration (GitHub token included), but it is a bugfix, not a breaking
  one: the previous behavior was never correct for that documented usage
  pattern (it silently wrote the wrapper document, not the value a
  consumer expected).
