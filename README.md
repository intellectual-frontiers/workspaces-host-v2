# workspaces-host-v2

A declarative, hermetically reproducible "Workspaces Host" engineering
sandbox — the from-scratch successor to
[`strategy-coach/workspaces-host`](https://github.com/strategy-coach/workspaces-host),
rebuilt for an era where AI coding agents (Claude Code, Copilot, Cursor,
Codex, ...) need environments they can spin up identically on a WSL2/Linux/
macOS host, in a container, or inside a cloud agent-harness session.

## Why a rewrite

The previous generation of this repository provisioned a host imperatively:
`chezmoi apply` plus a Homebrew/pkgx/eget/mise/SDKMAN! install list, mutating
a persistent machine over time. That model predates AI coding agents and
doesn't give them what they need — a hermetically reproducible closure that
is provably identical whether it's applied to a laptop, built into a CI
image, or handed to a cloud harness session.

This repository replaces that toolchain with **Nix flakes + home-manager**
as the single reproducibility engine (`flake.lock` pins every input
byte-for-byte, rather than drifting against whatever a package manager
resolves today), and builds **OCI images from the same flake outputs** so a
WSL host, CI, and a cloud agent-harness container are provably the same
closure.

See [`.specify/memory/constitution.md`](.specify/memory/constitution.md) for
the principles this project holds itself to, and the roadmap below for
what's built and what's planned.

## Roadmap

This project is built as a sequence of independent
[Spec Kit](https://github.com/github/spec-kit) feature specs, each with its
own spec → plan → tasks → implementation cycle and its own PR. No
big-bang rewrite commits.

| Phase | Status | Summary |
|---|---|---|
| 0 | ✅ | Bootstrap: Spec Kit, constitution |
| 1 | ✅ | Core flake: `flake.nix` + home-manager module (fish, oh-my-posh, direnv/nix-direnv, git config, core CLI toolset) |
| 2 | ✅ | Container/OCI parity |
| 3 | ⬜ | Agent-harness scaffolding (`.claude/`, `AGENTS.md`, MCP registry, skills convention) |
| 4 | ⬜ | Secrets (`sops-nix` / `op`, generalized backup/restore over `rclone`) |
| 5 | ⬜ | Agent sandboxing (network-egress allowlist) |
| 6 | ⬜ | Workspace profiles (per-persona flake outputs) |
| 7 | ⬜ | Doctor + rollback + CI (`nix flake check`) |

## Quickstart

See [`specs/001-core-flake-home-manager/quickstart.md`](specs/001-core-flake-home-manager/quickstart.md)
for the verified `nix flake check` / `home-manager switch --flake .#default`
smoke test.

## Working style

This repository dogtoods spec-driven development via Spec Kit's Claude Code
skills (`/speckit-specify`, `/speckit-plan`, `/speckit-tasks`,
`/speckit-implement`, etc., installed under `.claude/skills/`). See
`specs/` for feature specs as they land.
