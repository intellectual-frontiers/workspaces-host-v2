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
| 8 | ✅ | Ported the original repo's exact oh-my-posh theme (`coach.omp.json`) byte-for-byte |
| 9 | ✅ | Nerd Font support (installed font + human font-selection instructions) |
| 10 | ✅ | Workspace repo management (`mgit`, `~/workspaces`) - native port of `strategy-coach/workspaces` |

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

### 6. Select the Nerd Font in your terminal (required for the prompt's icons)

The prompt theme (`themes/oh-my-posh/coach.omp.json`, ported byte-for-byte
from the original `workspaces-host` repo) draws its OS/git/language/clock
icons from Nerd Font private-use-area glyphs. Step 4's activation already
installed a patched font — `home/fonts.nix` puts **JetBrainsMono Nerd
Font** into your user profile via `fonts.fontconfig.enable` and
`pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; }` — but which font
a *terminal emulator* actually renders with is a per-application GUI
setting. Nix/home-manager has no single "the terminal" to configure across
Windows Terminal, GNOME Terminal, iTerm2, etc., so this one step is
manual, and it's the one that actually makes the icons show up instead of
tofu boxes (`□`) or `?` glyphs. Do it once per terminal emulator you use
with this profile:

- **Verify the font is actually installed** first (confirms step 4 worked
  before you go looking for it in a font picker):
  ```console
  $ fc-list | grep "JetBrainsMono Nerd Font Mono"
  ```
  You should see several `.ttf` paths under
  `~/.nix-profile/share/fonts/truetype/NerdFonts/`.

- **Family name to select**: `JetBrainsMono Nerd Font Mono` (short alias:
  `JetBrainsMono NFM`). Use the **Mono** variant specifically — it forces
  the icon glyphs to the same fixed width as the text glyphs, which is
  what keeps the powerline/diamond segments in `coach.omp.json` aligned;
  the plain `JetBrainsMono Nerd Font` variant gives icons their natural
  (wider) width and can misalign the prompt.

- **WSL2 (Windows Terminal)**: the font must be installed on the
  **Windows** side too (WSL2's Linux filesystem fonts aren't visible to
  Windows' GDI). Grab the same release Nix fetched -
  [`JetBrainsMono.zip` from `ryanoasis/nerd-fonts` releases](https://github.com/ryanoasis/nerd-fonts/releases) -
  unzip it, select all the `.ttf` files, right-click → "Install for all
  users" (or double-click each → Install). Then in Windows Terminal:
  Settings → Profiles → **Debian** → Appearance → Font face →
  `JetBrainsMono NFM`.

- **Linux VM / Debian bare metal, GNOME Terminal** (Debian's default):
  Terminal → Preferences → your profile → Text → uncheck "Use the system
  fixed-width font" → Custom font → `JetBrainsMono Nerd Font Mono`.

- **Any other terminal emulator** (kitty, Alacritty, Konsole, iTerm2, …):
  the font is installed and discoverable via fontconfig
  (`fonts.fontconfig.enable` in `home/fonts.nix` ensures this), so it's
  just a matter of finding that emulator's font setting and entering the
  same family name, e.g. `font_family JetBrainsMono Nerd Font Mono` in
  `kitty.conf`.

- **Confirm it worked**: close and reopen the terminal (font changes
  rarely apply live) and either look at your actual prompt, or run
  `oh-my-posh print primary --config ~/.config/oh-my-posh/config.json` -
  the OS icon, branch icon, and segment separators should render as
  glyphs, not boxes or `?`.

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

## Managing your `~/workspaces` repos (`mgit`)

The original `strategy-coach/workspaces-host` relied on a *separate* repo,
[`strategy-coach/workspaces`](https://github.com/strategy-coach/workspaces),
for the actual "clone my repos into a governed `~/workspaces` layout"
strategy (its `mgit.ts`/`ws-ensure.ts` Deno scripts). That functionality is
now native to this repo - every profile installs an `mgit` command and
bootstraps `~/workspaces` on activation, so there's no second repo to clone
or a Deno runtime to install just to get your repos onto disk.

### The governed directory convention

Every repo `mgit` manages lives at
`~/workspaces/<git-host>/<org-or-group>/.../<repo>` - the exact same path
segments as the repo's own HTTPS clone URL, so the layout is predictable
and greppable no matter how many git hosts or orgs you work across:

```text
~/workspaces
├── github.com
│   ├── your-org
│   │   └── some-repo
│   └── another-org
│       └── another-repo
└── gitlab.example.com
    └── group
        └── subgroup
            └── repo
```

### Declaring which repos to track

`mgit ensure` reads a small JSON config at `~/workspaces/mgit.json` -
home-manager creates this file (and the `~/workspaces` directory itself)
once, empty, on first activation, and never touches it again, so your
choices persist across every future `home-manager switch`. Edit it to add
repos:

```console
$ cat ~/workspaces/mgit.json
{
  "repos": [
    { "repo": "github.com/your-org/some-repo" },
    { "repo": "github.com/your-org/other-repo", "fresh": true }
  ]
}
```

- `repo` is the host/org/repo path (no `https://` scheme) - the exact
  string mgit also uses as the on-disk path under `~/workspaces`.
- `"fresh": true` deletes and re-clones that repo on the next `ensure`
  instead of pulling (useful for a one-off "start this one over"; leave it
  off, or `false`, for normal day-to-day use).

### Running it

```console
$ mgit ensure     # clone anything new, `git pull --quiet` anything that exists - safe to run as often as you like
$ mgit status     # git status (dirty/ahead/behind/no-upstream) across every repo under ~/workspaces
$ mgit inspect    # list git hosts and repos referenced by *.mgit.code-workspace files
```

`mgit ensure` is fully idempotent - run it once a day, once an hour,
whatever you like; it only clones what's missing and quietly pulls
everything else.

### VS Code multi-root "monorepo" composition (optional)

If a repo `mgit` clones contains a `*.mgit.code-workspace` file (VS Code's
multi-root workspace format), `mgit ensure` automatically:

1. Symlinks that file to the root of `~/workspaces`, so you can open it
   directly in VS Code from one place regardless of which repo it lives in.
2. Reads its `folders[].path` entries and treats each one as another
   `mgit`-managed repo path, cloning/pulling it too - recursively, so
   repos can depend on other repos' workspace files without you having to
   list every transitive dependency in `mgit.json` yourself.

This lets several independent repos - potentially from different git
hosts or orgs - present themselves as one composed "monorepo" in the
editor, entirely via relative paths, with no submodules and no vendoring.
Example `my.mgit.code-workspace`, checked into a repo `mgit` manages:

```json
{
  "folders": [
    { "path": "github.com/your-org/some-repo" },
    { "path": "github.com/your-org/other-repo" },
    { "path": "gitlab.example.com/group/subgroup/repo" }
  ]
}
```

## PostgreSQL credentials (`~/.pgpass`, `~/.psqlrc`, `pgpass`)

Every profile ships `~/.psqlrc` (a full `psql` client config - colored
prompt, sane defaults, and a set of `\set` admin queries like `settings`,
`locks`, `dbsize`, `tablesize`) and bootstraps an empty `~/.pgpass` (mode
`600`, as `libpq` requires or it silently ignores the file) on first
activation - both ported from the original repo, `.pgpass` deliberately
left for you to fill in rather than generated with real credentials.

Add connections to `~/.pgpass` using a small comment-header convention -
one JSON-like descriptor line before each `hostname:port:database:username:password`
line:

```console
$ cat ~/.pgpass
# { id: "MYDB", description: "Purpose", boundary: "Network" }
192.168.2.24:5432:pgDB_name:pgDB_username:sup3rSecure!
```

Then look connections up by `id` with the `pgpass` command (a native port
of `netspective-labs/sql-aide`'s `pgpass.ts`, covering its most-used
subcommands):

```console
$ pgpass ls                                    # list every connection's id/description/host
$ pgpass test                                  # validate the file, reporting any parse issues
$ eval "$(pgpass env --conn-id=MYDB)"          # export PGHOST/PGPORT/PGDATABASE/PGUSER/PGPASSWORD
$ eval "$(pgpass psql --conn-id=MYDB)"         # runs "psql -h ... -p ... -d ... -U ..." for MYDB
$ pgpass url --conn-id=MYDB                    # postgres://user:pass@host:port/db
```

`--conn-id` takes an extended regex, so `--conn-id=".*"` matches every
connection (useful with `env` to export every connection's variables at
once, prefixed by each connection's own `id`).

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

This repository dogfoods spec-driven development via Spec Kit's Claude Code
skills (`/speckit-specify`, `/speckit-plan`, `/speckit-tasks`,
`/speckit-implement`, etc., installed under `.claude/skills/`). See
`specs/` for feature specs as they land.

## Maintaining this repo with Claude Code

Every phase and fix in this repository so far - the original 7-phase
rewrite, the theme port, this Nerd Font feature - was designed, implemented,
verified, and merged by Claude Code, not hand-written and then documented
after the fact. That's intentional: this repo is meant to keep being
maintained that way, by whoever picks it up next (human or AI). This
section is the playbook for doing that, including the part that's easy to
let rot - keeping the Spec Kit specs honest as the actual code moves on.

### The loop for any change, large or small

1. **Point Claude Code at this README and `.specify/memory/constitution.md`**
   first if it's a fresh session - the constitution captures the invariants
   (pinned inputs, host/container closure parity, small independent PRs,
   etc.) that every prior feature was held to, and this README's Roadmap
   section is the running changelog of what already exists.
2. **Branch per feature/fix**: `git checkout -b NNN-short-name` off `main`,
   `NNN` one higher than the last `specs/` directory.
3. **Spec it before coding it**, even for something that feels small:
   - `/speckit-specify` - what changes and why, user stories, acceptance
     scenarios, explicit edge cases and out-of-scope items (see any
     `specs/*/spec.md` for the shape).
   - `/speckit-clarify` - if the ask is ambiguous, resolve it here rather
     than guessing mid-implementation.
   - `/speckit-plan` - technical approach, constitution check, files that
     will change.
   - `/speckit-tasks` - a checklist scoped to independently-testable user
     stories, checked off as work actually completes (not pre-checked).
   - `/speckit-checklist` - for anything with fiddly acceptance criteria
     worth a dedicated review pass.
   - `/speckit-implement` - do the work the plan and tasks describe.
   - `/speckit-analyze` - sanity-check spec/plan/tasks/code consistency
     before calling a feature done.
4. **Verify for real, not just "it builds"**: `nix build
   .#homeConfigurations.default.activationPackage`, an actual activation
   (`./result/activate` as the profile's configured user), and running the
   actual command/tool/config being changed - the same standard every
   `specs/*/tasks.md` verification step already holds itself to. A change
   that only type-checks is not done.
5. **Run `nix flake check --all-systems`** before opening a PR.
6. **One small PR per feature/fix**, merged the same way this project's
   history was built (direct fast-forward to `main` has been more reliable
   here than the GitHub merge API) - never a giant multi-phase PR.

### Keeping the Spec Kit specs up to date (don't let them drift)

A spec that no longer matches the code is worse than no spec - it actively
misleads the next reader, human or AI, who trusts it instead of the diff.
Treat `specs/NNN-*/{spec.md,plan.md,tasks.md}` as living documents scoped to
their feature, not a one-time write-up:

- **A follow-up fix to an already-merged feature** (a review comment, a bug
  found later, a small scope correction) updates that feature's own
  `tasks.md` (add/check off the task) and, if the change alters behavior or
  acceptance criteria rather than just fixing a bug in the existing
  criteria, its `spec.md`/`plan.md` too - in the *same* commit/PR as the
  code change, not as a separate cleanup pass that may never happen.
- **A change that doesn't fit any existing feature's scope** gets its own
  new `specs/NNN-.../` via `/speckit-specify`, the same as any other
  feature - resist folding an unrelated change into an existing spec just
  because it's a nearby file (see feature 008's own spec, which exists
  specifically because a placeholder from feature 001 needed a real,
  separately-documented correction rather than a silent edit).
- **When asked to audit freshness** (or periodically, on general
  principle): run `/speckit-analyze` per feature, or diff each
  `specs/*/tasks.md` checklist against what the code under its "Project
  Structure" section actually does today; a checked-off task whose file no
  longer exists or behaves differently is drift to fix, not to ignore.
- **The root README itself is part of this loop**: its Roadmap section and
  the per-environment Installation steps are living documentation too - a
  feature that changes user-facing behavior (like this one, adding a
  required manual font-selection step) updates README.md in the same PR,
  same as its spec.
