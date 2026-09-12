# workspaces-host-v2

A ready-to-use engineering sandbox for your own computer. One command
gives you a configured shell and prompt, git and database credentials
handled safely, a way to keep many git repositories organized, and a
growing set of everyday developer tools - all set up identically every
time, whether that's on your Windows laptop (via WSL), a Linux machine,
a Mac, inside a container, or in a cloud AI-agent session.

It's built with **Nix flakes + home-manager**: the whole setup is
described in code (this repository) rather than a list of manual steps,
so it rebuilds byte-for-byte the same way anywhere, and a future update
to it is just a `git pull` plus one command away (see "Keeping your
sandbox in sync" below).

See [`.specify/memory/constitution.md`](.specify/memory/constitution.md)
for the principles behind these design choices.

## What you get

- A configured shell and prompt (fish + oh-my-posh) that looks and
  behaves the same on every machine you use it on.
- Git and database credentials handled safely by default, with a simple,
  documented way to update them from the command line (see "Updating
  your Git identity, and other secrets, from the CLI" below).
- `mgit`: clone and update many git repositories into one predictable
  folder layout under `~/workspaces`, plus tools for making the same
  change across many of them at once.
- Compliance and observability tooling (`osquery`, `cnquery`,
  `steampipe`, `OpenObserve`, `surveilr`) ready to audit the sandbox
  itself.
- A Java toolchain, PostgreSQL client tooling, and other everyday CLI
  tools, all pinned to exact, reproducible versions.
- The exact same environment available as a container image, for CI or
  a cloud AI-agent session.
- A `doctor` command that checks everything is actually working, and an
  instant rollback if a change ever goes wrong.

## Installation

This gets you a fully working shell with everything installed and turned
on. **If you're on Windows, start with the section right below** - that's
what most people reading this want. Already on Linux or a Mac? Skip
ahead to "Other platforms."

A few terms used below, in plain language:

- **Nix** is the tool that installs everything here - the shell, the
  prompt, git setup, every CLI tool - from one description, the same way
  every time.
- **A "flake"** is just what this repository is, in Nix's terms: a
  self-contained description of the whole setup.
- **"Activating"** means telling Nix to actually apply that setup to your
  user account.

### Windows (via WSL) — start here

WSL turns on a real Linux system that runs alongside your normal Windows
apps - not an emulator, not a virtual machine you have to manage
yourself. Everything below happens inside that Linux system (a window
titled "Debian"), except step 1.

1. **Open PowerShell as Administrator.** Click Start, type `powershell`,
   then right-click "Windows PowerShell" in the results and choose "Run
   as administrator."
2. **Install WSL with Debian Linux** by running this in that PowerShell
   window:
   ```powershell
   wsl --install -d Debian
   ```
   This may ask you to restart your computer. If it does, restart, then
   continue to the next step.
3. **Open "Debian"** from the Start menu (search for it if it's not
   pinned). The first time it opens, it asks you to choose a Linux
   username and password - these can be anything you like, and are
   separate from your Windows login.
4. **From inside that Debian window**, install two small prerequisites:
   ```console
   $ sudo apt update && sudo apt install -y curl git
   ```
5. **Install Nix**, which installs and manages everything else:
   ```console
   $ sh <(curl -L https://nixos.org/nix/install) --no-daemon
   ```
   Answer `y`/`yes` to anything it asks. When it finishes, close the
   Debian window and reopen it so the `nix` command becomes available.
6. **Turn on the one Nix feature this repository needs** - a single
   command, no file to find and edit by hand:
   ```console
   $ mkdir -p ~/.config/nix
   $ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```
7. **Download and apply this setup:**
   ```console
   $ git clone https://github.com/intellectual-frontiers/workspaces-host-v2.git ~/.workspaces-host-v2
   $ cd ~/.workspaces-host-v2
   $ nix build .#homeConfigurations.default.activationPackage
   $ ./result/activate
   ```
   This downloads everything the setup needs and can take a few minutes
   the first time - that's expected. The leading `.` in
   `.workspaces-host-v2` just keeps it out of a plain `ls` of your home
   folder - it's a completely normal folder otherwise, and `cd
   ~/.workspaces-host-v2` gets you there any time.
8. **Check that it worked:**
   ```console
   $ doctor
   ```
   Every line should say `PASS`. A `WARN` about your git name/email is
   normal on a brand-new machine - see "Updating your Git identity, and
   other secrets, from the CLI" below to fix it.
9. **(Recommended) install the prompt's icon font** - see "Fonts for the
   prompt icons" below. It's a couple of extra steps, and the prompt
   still works without it, just with plain boxes instead of icons.

That's it - from now on, every new Debian/WSL window already has this
setup active. To pick up future improvements to it, see "Keeping your
sandbox in sync" below.

*Want to build/run this repository's container images inside WSL too?*
That needs `systemd`, which is left off above to keep this install as
simple as possible. See "Other platforms" below for the systemd-enabled
install if you need it.

### Fonts for the prompt icons

The colorful prompt uses small icons (branch name, folder, a clock, ...)
from a "Nerd Font" - a regular monospace font with extra symbols added.
Step 7 above already installs the font file itself into your account;
this step is about telling your actual terminal window to use it, which
is a setting in the terminal app itself, not something Nix can turn on
for you.

- **Check the font is actually there** first:
  ```console
  $ fc-list | grep "JetBrainsMono Nerd Font Mono"
  ```
  You should see several `.ttf` file paths printed.

- **The exact font name to pick**: `JetBrainsMono Nerd Font Mono` (also
  shown as `JetBrainsMono NFM` in some menus). Use the **Mono** one
  specifically - the other variants can make the prompt's icons and text
  misalign.

- **On Windows (Windows Terminal)**: the font needs to be installed on
  the **Windows side** too, not just inside Debian/WSL - Windows can't
  see fonts that only exist inside the Linux filesystem.
  1. Download [`JetBrainsMono.zip`](https://github.com/ryanoasis/nerd-fonts/releases)
     from the Nerd Fonts project (the same one WSL just installed for
     Linux).
  2. Unzip it, select all the `.ttf` files, right-click → "Install for
     all users" (or double-click each file → Install).
  3. Open Windows Terminal → Settings → Profiles → **Debian** →
     Appearance → Font face → choose `JetBrainsMono NFM`.

- **On Linux with GNOME Terminal** (the default on Debian): Terminal →
  Preferences → your profile → Text → uncheck "Use the system
  fixed-width font" → Custom font → `JetBrainsMono Nerd Font Mono`.

- **Any other terminal app** (kitty, Alacritty, Konsole, iTerm2, ...):
  the font is already installed and discoverable system-wide, so just
  find that app's own font setting and type in the same name, e.g.
  `font_family JetBrainsMono Nerd Font Mono` in `kitty.conf`.

- **Check it worked**: close and reopen your terminal window (font
  changes usually don't apply to windows already open) and look at your
  prompt - you should see actual icons, not boxes or `?` marks.

### Other platforms (Linux or macOS, no WSL)

Everything above still applies - just skip the Windows-only parts
(steps 1-3) and use these small adjustments:

**Linux (a VM, or directly on a real machine), Debian or a Debian-based
distro (Ubuntu, etc.):**

- Start straight at step 4 (`apt install`) - just open a regular
  terminal.
- In step 5, use the daemon-based install instead, since real Linux
  already has `systemd` (this is a small quality-of-life improvement,
  not required):
  ```console
  $ sh <(curl -L https://nixos.org/nix/install) --daemon
  ```
- Want to build/run this repository's container images? Also install
  Docker: `sudo apt install -y docker.io` (or see
  [docs.docker.com](https://docs.docker.com/engine/install/debian/) for
  another distro's package).
- Everything else (steps 4, 6-9) is identical.

**macOS:**

- Skip the `apt install` in step 4 too - macOS already has `curl`/`git`
  (or get them via Homebrew or the Xcode Command Line Tools).
- Step 5's installer works the same way on macOS, Apple Silicon or
  Intel:
  ```console
  $ sh <(curl -L https://nixos.org/nix/install)
  ```
- In step 7, macOS's setup isn't called `default` - use your actual
  system name everywhere a command below says `default`:
  ```console
  $ nix build .#homeConfigurations.aarch64-darwin.activationPackage   # Apple Silicon
  $ nix build .#homeConfigurations.x86_64-darwin.activationPackage    # Intel
  $ ./result/activate
  $ home-manager switch --flake .#aarch64-darwin   # for future updates
  ```
- A handful of pieces (container sandboxing, and any tool that only
  exists for Linux) aren't installed on macOS - everything else is
  identical.

**Windows without WSL:** not possible, and there's nothing to document -
Nix needs a real Linux or macOS system underneath it, and WSL (above) is
exactly that (genuine Linux, not an emulator), so it's the only Windows
path.

## Quickstart

See [`specs/001-core-flake-home-manager/quickstart.md`](specs/001-core-flake-home-manager/quickstart.md)
for the verified `nix flake check` / `home-manager switch --flake .#default`
smoke test.

## Managing your `~/workspaces` repos (`mgit`)

`mgit` clones and updates your git repositories into one predictable
folder layout under `~/workspaces`. Every profile installs the `mgit`
command and creates `~/workspaces` automatically on activation - there's
nothing extra to install to get your repos organized.

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

### Bulk changes across many repos (`git-extras`, `git-xargs`)

`mgit` (above) governs *which* repos land under `~/workspaces`; these two
tools are for making the same change *across* many of them at once:

- **`git-extras`** - a grab-bag of everyday `git <cmd>` subcommands
  (`git summary`, `git changelog`, `git effort`, `git delete-merged-branches`,
  ...), installed by default.
- **`git-xargs`** ([gruntwork-io/git-xargs](https://github.com/gruntwork-io/git-xargs)) -
  run a command, or a small Go callback, against many GitHub repos in one
  shot and open a PR with the results in each. Installed by default, and
  a natural fit once you have several repos under `~/workspaces` (via
  `mgit`) and want to land the same fix in all of them:
  ```console
  $ git-xargs --repos repo1,repo2,repo3 --branch-name my-fix --commit-message "my fix" -- ./my-script.sh
  ```
  See its own README for the full flag set (repo selection via
  `--repos`/`--repo-file`/a GitHub org, dry-run mode, PR title/body,
  etc.) - this repo just makes sure the binary is on `PATH`.

## PostgreSQL credentials (`~/.pgpass`, `~/.psqlrc`, `pgpass`)

Every profile ships `~/.psqlrc` (a full `psql` client config - colored
prompt, sane defaults, and a set of `\set` admin queries like `settings`,
`locks`, `dbsize`, `tablesize`) and bootstraps an empty `~/.pgpass` (mode
`600`, as `libpq` requires or it silently ignores the file) on first
activation - `~/.pgpass` deliberately starts out empty for you to fill in
rather than pre-populated with anything.

Add connections to `~/.pgpass` using a small comment-header convention -
one JSON-like descriptor line before each `hostname:port:database:username:password`
line:

```console
$ cat ~/.pgpass
# { id: "MYDB", description: "Purpose", boundary: "Network" }
192.168.2.24:5432:pgDB_name:pgDB_username:sup3rSecure!
```

Then look connections up by `id` with the `pgpass` command (inspired by
`netspective-labs/sql-aide`'s `pgpass.ts`, covering its most-used
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

## Compliance & observability tooling

This sandbox includes tooling for auditing itself - useful for SOC2 and
similar compliance requirements, or just for understanding what's
actually running on the machine. Every profile installs all five, ready
to use with nothing extra to opt into:

- **`osqueryi`** (interactive) / `osqueryd` (daemon) - SQL-queryable
  operating-system instrumentation (processes, open files, listening
  sockets, installed packages, ...). Nixpkgs packages `osquery` as
  Linux-only (`meta.platforms = platforms.linux` - it wraps
  Linux-specific instrumentation), so it's only installed on
  `x86_64-linux`/`aarch64-linux`; `doctor` reports this as an informational
  WARN, not a FAIL, on Darwin.
- **`cnquery`** - Mondoo's cloud-native, graph-based asset inventory query
  tool; answers the same category of "what does this box/cloud
  account/container actually look like" questions as `osquery`, but
  across cloud/Kubernetes/API resources too, not just the local host.
- **`steampipe`** - queries cloud, code, and log sources with plain SQL
  via a Postgres foreign-data-wrapper interface; complements
  `osquery`/`cnquery` when the audit question is more naturally a SQL
  join across several plugins' tables than a one-off query.
- **`openobserve`** - a self-hostable logs/metrics/traces backend (an
  Elasticsearch/Splunk/Datadog alternative) for the sandbox's own
  application-lifecycle observability. It's a binary on `PATH`, not a
  running service - start it yourself (`openobserve` runs a local server)
  when you actually want to ingest and query telemetry.
- **`surveilr`** - opsfolio's Resource Surveillance and Integration
  Engine; walks files/databases/APIs and resource-surveils them into a
  local SQLite database, the same "capture evidence once, query it
  however you like" idea `osquery`/`cnquery` apply to live system state,
  applied to arbitrary resources instead. Upstream (`surveilr/packages`)
  only publishes `x86_64` release binaries for Linux and Darwin - no
  `aarch64` asset of either kind exists yet - so it's installed on
  `x86_64-linux`/`x86_64-darwin` only; `doctor` reports its absence
  elsewhere as an informational WARN, not a FAIL (see `pkgs/surveilr`).

None of these run anything by default - they're audit/query tools you
reach for, not background daemons this repository starts for you.

## Java toolchain

Every profile installs a JDK (`java`) and Maven (`mvn`), with `JAVA_HOME`
already set - no separate version manager needed. Nix itself already
pins reproducible versions for every tool in this setup, Java included,
so a second version manager on top of it would just duplicate that job.

If you need a different JDK version or vendor than the one nixpkgs pins
here, override `home/java.nix`'s `pkgs.jdk`/`pkgs.maven` in a fork (e.g.
`pkgs.temurin-bin` for a specific Temurin release), the same override
pattern as every other default in this repo (git identity, the Nerd
Font choice, etc.) - see `specs/015-java-toolchain/spec.md` for the exact
packages this pins today.

## Keeping your sandbox in sync

New features and fixes land on this repo's `main` as small, independent,
merged PRs. Your machine doesn't pick those up by itself; here's how to
stay current.

### The manual way (always works)

```console
$ cd ~/.workspaces-host-v2   # or wherever $WORKSPACES_HOST_REPO points
$ git pull
$ home-manager switch --flake .#default   # or your profile
```

### The one-command way

Every profile installs `workspaces-host-update`, which does exactly that:

```console
$ workspaces-host-update
```

It reads two environment variables (both have sane defaults, override
either in a fork or via `home.sessionVariables` if you need to):

- `WORKSPACES_HOST_REPO` (default `~/.workspaces-host-v2`) - where this
  repo is cloned.
- `WORKSPACES_HOST_PROFILE` (default `default`) - which flake profile to
  switch to (`default`, or a persona like `backend`).

### The nudge (so you actually remember to)

Every profile's fish config checks, once per day, in the background
(never blocking shell startup, and silently skipped if there's no
network), whether `$WORKSPACES_HOST_REPO`'s `origin/main` has moved. If
it has, your next new shell prints:

```text
workspaces-host-v2: 3 commit(s) behind origin/main - run workspaces-host-update to pick up new features
```

This is informational only - it never runs `git pull` or `home-manager
switch` for you. Applying a change is always your own explicit
`workspaces-host-update` (or the manual two-liner above), never automatic,
since a `home-manager switch` can restructure your shell/prompt/tool
environment and shouldn't happen unattended.

## Updating your Git identity, and other secrets, from the CLI

### Your name and email (git identity)

This setup writes `~/.gitconfig` for you from a file inside this
repository, so editing `~/.gitconfig` by hand gets silently overwritten
the next time you sync (see "Keeping your sandbox in sync" above).
Change your name/email here instead, with one command:

```console
$ sed -i 's/Workspace Engineer/Your Name/; s/workspace@example.invalid/you@example.com/' ~/.workspaces-host-v2/home/git.nix
$ workspaces-host-update
```

Replace `Your Name` and `you@example.com` with your own, then run it.
`doctor`'s `WARN` about your git identity goes away once this is applied.

### Database passwords (`~/.pgpass`)

See "PostgreSQL credentials" above - `~/.pgpass` is a plain text file, one
line per connection (`hostname:port:database:username:password`) with a
short description above it. Add to it directly from the CLI:

```console
$ cat >> ~/.pgpass <<'EOF'
# { id: "MYDB", description: "My database", boundary: "Local" }
localhost:5432:mydb:myuser:mypassword
EOF
```

### GitHub/GitLab tokens, and other secrets that expire

Two habits keep real credentials out of git history entirely:

- Keep `.env` and any real credential file in your *project's own*
  `.gitignore` (not this repository's - every project's secrets are
  different).
- Before committing, check what's actually staged - `git diff --staged` -
  especially after a broad `git add`. `gitleaks` is installed and ready
  to scan a repo for anything that looks like a secret:
  ```console
  $ gitleaks detect --source . -v
  ```

For a GitHub/GitLab token (or any secret a CLI tool needs), this is the
simplest safe way to handle it:

1. **Get a short-lived token** from GitHub/GitLab (both let you set an
   expiration date when you create one) instead of a permanent one.
2. **Encrypt it once**, using the `age`/`sops` tools this setup already
   installs:
   ```console
   $ echo -n "ghp_yourToken" | sops --encrypt --age <your-age-public-key> /dev/stdin > github-token.enc.yaml
   ```
3. **Tell this setup about it**, in your home-manager config:
   ```nix
   workspacesHost.secrets.github-token = {
     sopsFile = ./github-token.enc.yaml;
     path = "github-token";
   };
   ```
   Run `workspaces-host-update` (or `home-manager switch`) and the real
   value lands at `~/.local/state/workspaces-host/secrets/github-token` -
   readable only by you, never in a file you'd accidentally commit.
4. **Use it only where you need it.** In that one project, add a
   `.envrc` (this setup already turns on `direnv`, which loads and
   unloads environment variables automatically as you move in and out
   of a folder):
   ```console
   $ echo 'export GITHUB_TOKEN=$(cat ~/.local/state/workspaces-host/secrets/github-token)' >> .envrc
   $ direnv allow
   ```
   Now any tool that reads `$GITHUB_TOKEN` (like `gh`) sees it
   automatically inside that folder, and it disappears the moment you
   leave. The same steps work for `GITLAB_TOKEN`, a cloud provider
   token, or anything else.

**When a token expires or needs rotating**: repeat step 2 with the new
value, then run `workspaces-host-update` again. Everything else - the
decrypted file, every `.envrc` that reads it - picks up the new value
automatically; there's no code to change and no old plaintext left
behind.

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

This is a real, tested rollback (a two-generation activate/rollback cycle
was exercised during development), not a theoretical capability - see the
same quickstart for the full before/after transcript.

## Working style

This repository dogfoods spec-driven development via Spec Kit's Claude Code
skills (`/speckit-specify`, `/speckit-plan`, `/speckit-tasks`,
`/speckit-implement`, etc., installed under `.claude/skills/`). See
`specs/` for feature specs as they land.

## Maintaining this repo with Claude Code

Every feature in this repository so far was designed, implemented,
verified, and merged by Claude Code, not hand-written and then documented
after the fact. That's intentional: this repo is meant to keep being
maintained that way, by whoever picks it up next (human or AI). This
section is the playbook for doing that, including the part that's easy to
let rot - keeping the Spec Kit specs honest as the actual code moves on.

### The loop for any change, large or small

1. **Point Claude Code at this README and `.specify/memory/constitution.md`**
   first if it's a fresh session - the constitution captures the invariants
   (pinned inputs, host/container closure parity, small independent PRs,
   etc.) that every prior feature was held to, and `specs/` itself is the
   running changelog of what already exists (ask an AI harness to
   summarize it if you want a roadmap-style overview - it's generated on
   demand rather than hand-maintained here).
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
  because it's a nearby file.
- **When asked to audit freshness** (or periodically, on general
  principle): run `/speckit-analyze` per feature, or diff each
  `specs/*/tasks.md` checklist against what the code under its "Project
  Structure" section actually does today; a checked-off task whose file no
  longer exists or behaves differently is drift to fix, not to ignore.
- **The root README itself is part of this loop**: its Installation steps
  and every feature section are living documentation too - a
  feature that changes user-facing behavior updates README.md in the same
  PR, same as its spec.
