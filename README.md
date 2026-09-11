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
| 3 | ✅ | Agent-harness scaffolding (`.claude/`, `AGENTS.md`, MCP registry, skills convention) |
| 4 | ✅ | Secrets (`sops-nix` / `op`, generalized backup/restore over `rclone`) |
| 5 | ✅ | Agent sandboxing (network-egress allowlist) |
| 6 | ✅ | Workspace profiles (per-persona flake outputs) |
| 7 | ✅ | Doctor + rollback + CI (`nix flake check`) |

## Installation

These steps take a machine with nothing on it to a working
`home-manager switch --flake .#default` (Fish, oh-my-posh, direnv, git,
`specify`/`backlog`/`doctor`/the ported scripts, all on `PATH`). **Debian
is this project's reference/default distro** — the commands below are
written for Debian (12 "bookworm" or newer) or Debian-derivatives
(Ubuntu, etc.); adjust the one `apt` line for a non-Debian base if you're
not on one.

The steps are identical whether Debian is running under WSL2, inside a
VM, or directly on bare metal — Nix itself doesn't care. Each target
below only calls out what's actually different for it.

### 1. Prerequisites (all targets)

```console
$ sudo apt update && sudo apt install -y curl git
```

### 2. Install Nix

Prefer the **multi-user (daemon) install** — it needs `systemd`, which a
normal VM or bare-metal Debian install already has:

```console
$ sh <(curl -L https://nixos.org/nix/install) --daemon
```

Follow the installer's prompt to open a new shell (or `source
/etc/profile.d/nix.sh`) afterward so `nix` is on `PATH`.

If `systemd` genuinely isn't available (see the WSL2 note below), use
the **single-user install** instead — this is the exact fallback this
project's own development sandbox needed, and it's fully sufficient for
a single-developer machine:

```console
$ sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

### 3. Enable flakes (both install modes)

```console
$ mkdir -p ~/.config/nix
$ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

(For a multi-user install, this can instead go in `/etc/nix/nix.conf` to
apply for every user on the machine.)

### 4. Clone this repo and do the first activation

```console
$ git clone https://github.com/intellectual-frontiers/workspaces-host-v2.git
$ cd workspaces-host-v2
$ nix build .#homeConfigurations.default.activationPackage
$ ./result/activate
```

This works even before `home-manager` itself is on `PATH` — the first
activation installs it (via `programs.home-manager.enable`), so every
activation after this one can just be:

```console
$ home-manager switch --flake .#default
```

### 5. Verify

```console
$ doctor
```

Every check should report `PASS` (an unset git identity reports `WARN`,
which is expected on a brand-new machine — override the placeholder
identity in [`home/git.nix`](home/git.nix), see
[the Phase 1 quickstart's "Git identity" section](specs/001-core-flake-home-manager/quickstart.md)).

---

### WSL2 (Windows Subsystem for Linux)

1. From an elevated PowerShell on Windows: `wsl --install -d Debian`
   (installs WSL2 itself if it isn't already, plus a Debian distro).
2. Launch "Debian" from the Start menu and create your Unix user when
   prompted.
3. **Enable `systemd`** (needed for the multi-user Nix install, and for
   `docker`/`dockerd` if you plan to build/run this flake's OCI images
   inside WSL2 too): create or edit `/etc/wsl.conf` inside the Debian
   shell:
   ```console
   $ sudo tee /etc/wsl.conf >/dev/null <<'EOF'
   [boot]
   systemd=true
   EOF
   ```
   Then, from PowerShell: `wsl --shutdown`, and reopen the Debian shell.
4. Follow steps 1-5 above from inside that Debian shell.

If you'd rather not touch `wsl.conf`, the single-user Nix install (step
2's fallback above) works in WSL2 without `systemd` too.

### Linux VM (any hypervisor)

Any VM running Debian (via VirtualBox, UTM, Multipass, a cloud provider's
Debian image, etc.) already has `systemd` — just follow steps 1-5 above
with no changes. If you plan to build/run this flake's OCI images
(`packages.<system>.oci-image*`) inside the VM, also install Docker
(`sudo apt install -y docker.io` on Debian, or see
[docs.docker.com](https://docs.docker.com/engine/install/debian/) for the
upstream package).

### Debian bare metal

Same as the VM case — steps 1-5, no changes. This is the most direct
path: no virtualization layer, no WSL translation layer, just Debian and
Nix.

## Quickstart

See [`specs/001-core-flake-home-manager/quickstart.md`](specs/001-core-flake-home-manager/quickstart.md)
for the verified `nix flake check` / `home-manager switch --flake .#default`
smoke test.

## Health check & rollback

Run `doctor` (installed by every profile) to check that Nix, the shell
stack, git, and every ported CLI tool are actually present and working:

```console
$ doctor
```

It prints one `PASS`/`WARN`/`FAIL` line per check and exits non-zero only
on a real failure. See
[`specs/007-doctor-rollback-ci/quickstart.md`](specs/007-doctor-rollback-ci/quickstart.md)
for a full transcript.

Rolling back a bad change needs no extra tooling - home-manager's own
generations are already a full history:

```console
$ home-manager generations
2026-09-11 22:15 : id 2 -> /nix/store/...-home-manager-generation
2026-09-11 22:15 : id 1 -> /nix/store/...-home-manager-generation

$ /nix/store/...-home-manager-generation/activate   # re-activate an older one
```

This is a real, verified rollback (a two-generation activate/rollback
cycle was exercised during Phase 7's implementation), not a theoretical
capability - see the same quickstart for the full before/after transcript.

## Working style

This repository dogtoods spec-driven development via Spec Kit's Claude Code
skills (`/speckit-specify`, `/speckit-plan`, `/speckit-tasks`,
`/speckit-implement`, etc., installed under `.claude/skills/`). See
`specs/` for feature specs as they land.
