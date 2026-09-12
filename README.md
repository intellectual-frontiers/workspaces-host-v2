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

## Why this exists

The point isn't just "a nice shell" - it's that a human engineer, a
teammate who's new to Linux, a CI/CD pipeline, and an AI coding agent
(Claude Code, Codex, an autonomous CI bot, ...) can all open a terminal
on completely different machines and find the *exact same* structure:
the same place repos get cloned to (`~/workspaces`, managed by `mgit`),
the same command to check the environment (`doctor`), the same command
to update it (`workspaces-host-update`), the same shell, the same
tools, at the same versions. When everyone and everything working on a
project - across engineering, DevOps, and an AI agent doing a chunk of
the work overnight - shares one predictable layout, nobody (human or
machine) has to re-learn "how this particular person's/pipeline's
machine happens to be set up" before they can be useful on it.

That matters more, not less, now that AI has put a real command line
within reach of people who never expected to need one. Effectively
everyone is an engineer now, at least some of the time - and everyone
doing that work deserves the same consistent, good-looking, fully
capable Linux environment, not a stripped-down or inconsistent one just
because they're newer to it. On Windows, WSL already gives you the
Windows desktop, files, and apps you know; `workspaces-host` is what
gives the Linux side of that the same consistent, ready-to-go
engineering setup everyone else on the team has - so the "new to Linux"
part is the only unfamiliar piece, not the tooling itself.

This is also why AI CLIs are provisioned as part of the standard
environment (see "Setting up AI harness credentials" below): once an
engineer - technical or not - has an API key configured the safe way
this repo documents, they can point an AI harness at their own sandbox
and ask it to help configure or improve their setup, the same way it
would help with application code. That's a deliberate design goal, not
an accident: lowering the barrier to actually using and improving a real
engineering environment is the whole point.

But that consistency is the thing to protect. If an AI harness (or a
person) comes up with a genuinely good improvement while working in one
sandbox - a new tool, a better default, an extra `doctor` check, a
smarter install step - the right place for it is **this repository, via
a pull request**, not just that one person's credentials file or a
one-off tweak that only exists on their machine. Your credentials file
(see "Setting up your credentials" below) exists for things that are
genuinely personal - your name, your API keys - precisely so that
everything else stays shared and in sync across the whole team. A good
idea that only lives in one sandbox helps one person; the same idea
merged back here helps everyone (and every
CI run, and every agent) who uses this setup after that.

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
4. **From inside that Debian window, run this one line** - a brand-new
   Debian/WSL image doesn't include `curl` yet (nothing does, on a
   minimal install), so this first installs just enough (`curl`, `git`)
   to fetch and run the actual installer, which then does everything
   else itself (installs Nix, turns on the one Nix feature this setup
   needs, downloads this repo, applies it, and creates a blank
   credentials file for the next step):
   ```console
   $ sudo apt-get update && sudo apt-get install -y curl git && sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v2/main/install.sh)"
   ```
   `sudo` asks for the password you just set in step 3 - that's
   expected, and the only password prompt in this whole process. The
   whole line can take a few minutes the first time - that's expected.
   It's also safe to run again later (everything in it skips whatever's
   already done, and just updates/reapplies if you already have this
   installed) - that's literally what `workspaces-host-update` does
   under the hood, once you're set up (see "Keeping your sandbox in
   sync" below). If you'd rather see or control each step yourself, or
   the installer doesn't fit your setup, "What the installer actually
   does" below has the exact equivalent commands.
5. **Fill in your credentials, then apply them:**
   ```console
   $ nano ~/.config/workspaces-host/credentials
   $ workspaces-host-update
   ```
   Add your name, email, and any tokens/API keys you already have (leave
   the rest blank) - see "Setting up your credentials" below for exactly
   what goes in this file and why. `workspaces-host-update` applies it
   and finishes by running `doctor`, so you'll see a `PASS`/`WARN`/`FAIL`
   line for everything right there in the same command - a `WARN` for
   anything you left blank is normal and expected, not a problem to fix
   immediately.
6. **(Recommended) install the prompt's icon font** - see "Fonts for the
   prompt icons" below. It's a couple of extra steps, and the prompt
   still works without it, just with plain boxes instead of icons.

That's it - from now on, every new Debian/WSL window already has this
setup active. To pick up future improvements to it, see "Keeping your
sandbox in sync" below.

### What the installer actually does (manual steps, if you'd rather)

Everything `install.sh` does, spelled out - useful if you want to run it
yourself piece by piece, understand what it changed, or it doesn't cover
your exact setup:

```console
$ sudo apt update && sudo apt install -y curl git
$ sh <(curl -L https://nixos.org/nix/install) --no-daemon
```
Answer `y`/`yes` to anything the Nix installer asks. When it finishes,
close the Debian window and reopen it so the `nix` command becomes
available, then:
```console
$ mkdir -p ~/.config/nix
$ echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
$ git clone https://github.com/intellectual-frontiers/workspaces-host-v2.git ~/.workspaces-host-v2
$ cd ~/.workspaces-host-v2
$ nix build .#homeConfigurations.current.activationPackage --impure
$ ./result/activate
$ mkdir -p ~/.config/workspaces-host
$ cp ~/.workspaces-host-v2/credentials.example ~/.config/workspaces-host/credentials
$ chmod 600 ~/.config/workspaces-host/credentials
```
The leading `.` in `.workspaces-host-v2` just keeps it out of a plain
`ls` of your home folder - it's a completely normal folder otherwise, and
`cd ~/.workspaces-host-v2` gets you there any time. `current` and
`--impure` mean "build this for whoever's actually running it" - Nix
normally insists everything be fully self-contained (no reading your
actual username), so this one flag is how you tell it "yes, really use my
real account" instead of a placeholder one.

`install.sh` (in this repo) is the actual source of truth for these
steps - if it and this section ever disagree, trust the script; both are
plain, readable shell, worth a skim before you pipe them into a shell
either way.

*Want to build/run this repository's container images inside WSL too?*
That needs Docker, which needs `systemd` enabled in WSL - a separate,
optional step from anything above (Nix itself doesn't need `systemd`
either way). From an elevated PowerShell: create/edit `/etc/wsl.conf`
inside Debian with `[boot]` / `systemd=true`, then `wsl --shutdown` and
reopen Debian; then install Docker as described in "Other platforms"
below.

### Fonts for the prompt icons

The colorful prompt uses small icons (branch name, folder, a clock, ...)
from a "Nerd Font" - a regular monospace font with extra symbols added.
Step 4 above already installs the font file itself into your account;
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

Just skip the Windows-only parts (steps 1-3) and open a regular terminal
instead of "Debian" - steps 5-6 (your credentials, the font) are
identical everywhere. Step 4 (the installer) differs only in how you get
`curl`/`git` on the system in the first place, since `install.sh` itself
can't run until something has fetched it:

- **Linux (a VM, or directly on a real machine)**: many VM/cloud images
  already have `curl`/`git`; a genuinely minimal one (the same gap as
  fresh WSL/Debian above) won't. If `curl -V` says "command not found,"
  install both with your distro's own package manager first - `sudo
  apt-get install -y curl git` (Debian/Ubuntu), `sudo dnf install -y
  curl git` (RHEL/Fedora/CentOS), or `sudo pacman -Sy --noconfirm curl
  git` (Arch) - then run the same one-liner as step 4 above. From there,
  `install.sh` itself auto-detects whichever of those three families
  you're on for anything else it still needs - no manual adjustment
  needed. Want to build/run this repository's container images? Also
  install Docker: `sudo apt install -y docker.io` (Debian/Ubuntu - see
  [docs.docker.com](https://docs.docker.com/engine/install/) for another
  distro's package).
- **macOS**: `curl` and `git` are always already there (Apple ships
  both) - just run the plain one-liner from step 4 above (no
  `apt-get`/`dnf`/`pacman` prefix - those aren't macOS things), Apple
  Silicon or Intel, and it senses your system automatically (via
  `current`, see "What the installer actually does" above). A handful of
  pieces (container sandboxing, and any tool that only exists for Linux)
  aren't installed on macOS - everything else is identical.
- **A Linux distro `install.sh` doesn't recognize**: it tells you exactly
  that, and exits without changing anything - install `curl`/`git`
  yourself with your distro's own package manager, then re-run it; every
  step after that is distro-agnostic.

**Windows without WSL:** not possible, and there's nothing to document -
Nix needs a real Linux or macOS system underneath it, and WSL (above) is
exactly that (genuine Linux, not an emulator), so it's the only Windows
path.

## Setting up your credentials

Your git name/email, GitHub/GitLab tokens, and AI harness API keys all
go in **one plain text file, outside this repository entirely**:
`~/.config/workspaces-host/credentials`. It's just `KEY=value` lines -
no Nix syntax, no encryption tool to learn first - and `install.sh`
already created a blank one for you, ready to fill in, before it even
finished (see "What the installer actually does" above if you installed
manually instead).

Open it in any editor, fill in what you have (leave the rest blank),
save, and run `workspaces-host-update` to apply it:

```console
$ nano ~/.config/workspaces-host/credentials
```
```dotenv
GIT_NAME=Your Name
GIT_EMAIL=you@example.com

GITHUB_TOKEN=ghp_yourToken
GITLAB_TOKEN=

ANTHROPIC_API_KEY=sk-ant-yourRealKey
OPENAI_API_KEY=
GEMINI_API_KEY=
```
```console
$ workspaces-host-update
```

That one command re-applies your setup with the new values *and*
finishes by running `doctor`, so you see immediately whether everything
took effect - no separate "now go check it worked" step.

This file:

- **Never leaves your machine.** It lives outside this repository, so
  `git pull`/`workspaces-host-update` can never touch, overwrite, or
  conflict with it, and there's nothing here to accidentally commit.
- **Is protected the same way `~/.ssh` or `~/.aws/credentials` are**:
  `workspaces-host-update` sets it to mode 600 (readable only by you)
  every time it runs, and fixes the permissions automatically if
  anything ever loosens them; `doctor` checks this too.
- **Is read by a plain script, not by Nix.** `workspaces-host-update`
  parses it as plain `KEY=value` text (never `source`s it as a shell
  script, so a stray character in a token can't be executed as a
  command), writes your git name/email into a file git itself includes
  automatically, and drops each token/key into the same
  per-command-scoped mechanism this setup already uses for AI CLI
  credentials (see "Setting up AI harness credentials" below) - so a
  key is only ever visible to the one command that actually needs it,
  never the rest of your shell.

**Rotating a token or key**: edit the same line in
`~/.config/workspaces-host/credentials` and run `workspaces-host-update`
again. There's no encrypted file to re-generate and no old plaintext
left behind - the previous value is simply overwritten.

**File missing?** (You deleted it, or installed some other way and
skipped that step.) `workspaces-host-update` creates it from the same
template the moment it doesn't find one, prints what to do next, and
stops there without changing anything else - run it again once you've
filled the file in.

**Something else that needs a credential** (a cloud provider token, a
project-specific API key)? Add it to this same file with whatever name
makes sense (e.g. `AWS_ACCESS_KEY_ID=...`) - `workspaces-host-update`
writes any line that isn't `GIT_NAME`/`GIT_EMAIL` into
`~/.local/state/workspaces-host/secrets/env/<NAME>`, ready for a
project's own `.envrc` to pick up:

```console
$ echo 'export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$(cat ~/.local/state/workspaces-host/secrets/env/AWS_ACCESS_KEY_ID 2>/dev/null)}"' >> .envrc
$ direnv allow
```

(That `${AWS_ACCESS_KEY_ID:-...}` isn't just defensive habit - the next
section explains exactly why a `.envrc` should always be written this
way, not as a plain `export AWS_ACCESS_KEY_ID=$(cat ...)`.)

### Making a `.envrc` work locally *and* in CI/CD (or a container)

If you're new to programming, this part is easy to miss: the exact same
project usually runs in more than one place - your machine, a
teammate's machine, and an automated pipeline (GitHub Actions, GitLab
CI, a cloud build) or a container that runs your tests/deploys without
anyone typing a command by hand. Each of those places gets its
credentials differently:

- **In CI/CD or a container**, there's no
  `~/.config/workspaces-host/credentials` file - that sandbox doesn't
  exist there. Instead, the platform itself injects a secret directly
  as an environment variable (a GitHub Actions "repository secret," a
  GitLab CI/CD variable, a container's `--env`/`docker-compose.yml`
  entry) - it's already set by the time your code runs, with no `.envrc`
  or `direnv` involved at all.
- **On your machine**, in this sandbox, that same variable is
  deliberately *not* already set in your shell (see "Setting up your
  credentials" above for why) - it's sitting in a file at
  `~/.local/state/workspaces-host/secrets/env/<NAME>` instead, waiting
  for a project's `.envrc` to read it.

So a `.envrc` that just works everywhere needs to **prefer whatever's
already in the environment, and only fall back to your local sandbox's
file if nothing's there** - never the other way around, since
overwriting a value CI/CD already injected would silently use the wrong
credential in the one place that actually had the right one configured.
Shell's `${VAR:-fallback}` does exactly this in one line:

```console
$ cat .envrc
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$(cat ~/.local/state/workspaces-host/secrets/env/AWS_ACCESS_KEY_ID 2>/dev/null)}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-$(cat ~/.local/state/workspaces-host/secrets/env/AWS_SECRET_ACCESS_KEY 2>/dev/null)}"
$ direnv allow
```

Read it as: "use `$AWS_ACCESS_KEY_ID` if something already set it;
otherwise, read it from my local credentials file." In CI/CD or a
container, the variable is already set, so the `cat` never even runs -
your pipeline's own secret wins. On your machine, nothing set it yet, so
it falls through to the file you configured locally. The `2>/dev/null`
just means "leave it empty, don't print an error" if you haven't
actually filled in that particular credential yet - the same command
either way, everywhere your code runs.

### Advanced: encrypting a secret at rest with sops

The credentials file above is protected by ordinary file permissions,
the same trust model as `~/.ssh/id_ed25519` or `~/.netrc` with the right
mode - the right default for a personal, single-user sandbox. If you
specifically want field-level *encryption at rest* for one credential
(for example, because you back up or sync your `$HOME` config
somewhere), this setup still has `age`/`sops` available as an opt-in,
lower-level mechanism, unrelated to the credentials file above:

1. **Encrypt it once**, next to your advanced `local.nix` (see
   `local.nix.example`):
   ```console
   $ echo -n "ghp_yourToken" | sops --encrypt --output-type yaml --age <your-age-public-key> /dev/stdin > ~/.config/workspaces-host/github-token.enc.yaml
   ```
2. **Declare it** in `~/.config/workspaces-host/local.nix`:
   ```nix
   workspacesHost.secrets.github-token = {
     sopsFile = ./github-token.enc.yaml;
     path = "env/GITHUB_TOKEN";
   };
   ```
   Run `workspaces-host-update` and the real value is decrypted straight
   into the same `~/.local/state/workspaces-host/secrets/env/GITHUB_TOKEN`
   location the plain credentials file above would have written it to -
   both mechanisms feed the same place, so pick whichever one secret
   needs the extra step and leave the rest in the simple file.

**When a token expires or needs rotating** this way: repeat step 1 with
the new value, then run `workspaces-host-update` again.

### Database passwords (`~/.pgpass`)

See "PostgreSQL credentials" below - `~/.pgpass` is a plain text file, one
line per connection (`hostname:port:database:username:password`) with a
short description above it. Add to it directly from the CLI:

```console
$ cat >> ~/.pgpass <<'EOF'
# { id: "MYDB", description: "My database", boundary: "Local" }
localhost:5432:mydb:myuser:mypassword
EOF
```

### Keeping credentials out of git history

Two habits keep real credentials out of every project's git history
entirely, on top of the credentials file above (which is never inside
any git repo to begin with):

- Keep `.env` and any real credential file in your *project's own*
  `.gitignore` (not this repository's - every project's secrets are
  different).
- Before committing, check what's actually staged - `git diff --staged` -
  especially after a broad `git add`. `gitleaks` is installed and ready
  to scan a repo for anything that looks like a secret:
  ```console
  $ gitleaks detect --source . -v
  ```
- Get a short-lived token from GitHub/GitLab (both let you set an
  expiration date when you create one) instead of a permanent one, and
  rotate it in your credentials file the same way, per above.

### Setting up AI harness credentials

Every profile installs `nodejs` (needed by every AI CLI below) and
`aider-chat` (provider-agnostic, so it works with whichever API key you
have - already on PATH, nothing to install). The fast-moving hosted CLIs
below aren't packaged in this flake's pinned nixpkgs - install them with
their own `npm install -g`, same as upstream documents:

```console
$ npm install -g @anthropic-ai/claude-code   # provides: claude
$ npm install -g @openai/codex               # provides: codex
$ npm install -g @google/gemini-cli          # provides: gemini
$ gh extension install github/gh-copilot     # GitHub Copilot CLI, via gh
```

`doctor` checks whether each is installed and whether it has a key to
use.

**Giving each one its API key, safely**: add it to
`~/.config/workspaces-host/credentials` (see "Setting up your
credentials" above) and run `workspaces-host-update`:

```dotenv
ANTHROPIC_API_KEY=sk-ant-yourRealKey
```

This project's own constitution is explicit that a secret must never
become "an ambient environment variable available to an entire shell
session" - so instead of exporting your key into every shell,
`claude`/`codex`/`gemini`/`aider`/`gh`/`glab` each get their own fish
wrapper function (`home/ai-harness.nix`) that looks for their matching
key and sets it only for that one invocation. Run `claude` afterward and
its wrapper finds the value `workspaces-host-update` wrote, sets
`$ANTHROPIC_API_KEY` only for that one call, and never touches the rest
of your shell - `echo $ANTHROPIC_API_KEY` in the same window stays
empty. The same applies to `OPENAI_API_KEY` (`codex`),
`GEMINI_API_KEY`/`GOOGLE_API_KEY` (`gemini`), any of the four for
`aider` (it accepts whichever it finds), and `GITHUB_TOKEN`/
`GITLAB_TOKEN` (`gh`/`glab`). If a CLI supports its own browser-based
`login` command instead (Claude Code and Gemini CLI both do), that works
too - the wrapper is a transparent no-op when no matching credential is
configured, and `doctor` only warns if neither a configured credential
nor an existing login is present.

**Using one of these to improve your setup?** Once a harness has a key,
it's genuinely useful for exploring and fixing your own sandbox -
diagnosing a `doctor` `WARN`, editing your credentials file, adding a
project to `mgit.json`. If it comes up with something that would help
beyond your own machine (a new tool, a better default, another `doctor`
check), open a pull request against this repository with it instead of
only keeping the change local - see "Why this exists" above for why
that matters here specifically.

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
`pkgs.temurin-bin` for a specific Temurin release) - see
`specs/015-java-toolchain/spec.md` for the exact packages this pins
today.

## Keeping your sandbox in sync

New features and fixes land on this repo's `main` as small, independent,
merged PRs. Your machine doesn't pick those up by itself; here's how to
stay current.

### The manual way (always works)

```console
$ cd ~/.workspaces-host-v2   # or wherever $WORKSPACES_HOST_REPO points
$ git pull
$ home-manager switch --flake .#current --impure   # or your profile
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
- `WORKSPACES_HOST_PROFILE` (default `current`) - which flake profile to
  switch to (`current`, a persona like `current-backend`, or the fixed
  test identities `default`/`backend`/etc. if you specifically want
  those instead).

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

## Health check & rollback

Run `doctor` (installed by every profile) to check that Nix, the shell
stack, git, and every ported CLI tool are actually present and working -
plus a set of checks aimed specifically at mistakes that are easy to
make if you're new to Linux/WSL: whether
`~/.config/workspaces-host/credentials` exists with the right
permissions, GitHub/GitLab authentication (including via a token from
that file), whether the AI harness CLIs (Claude Code, Codex, Gemini
CLI, aider, GitHub Copilot CLI) are installed and have a credential to
use, SSH key existence and permissions, working under WSL's slower
`/mnt/c` Windows filesystem by mistake, low disk space, a misconfigured
locale, a plaintext `~/.netrc` with the wrong permissions, an overly
permissive `umask`, and Docker group membership:

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
