#!/bin/sh
# install.sh: one-step installer for workspaces-host-v2. Safe to re-run -
# every step is idempotent (skips whatever's already done, and re-runs
# just pull + rebuild + reactivate if you've already installed once).
#
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/intellectual-frontiers/workspaces-host-v2/main/install.sh)"
#
# Deliberately NOT `curl ... | sh`: that form hands this script's own
# stdin to the shell running it, so anything downstream that ever needs
# to read real terminal input (a sudo password prompt, an installer
# confirmation) can't. `sh -c "$(curl ...)"` downloads the whole script
# into an argument first, so your terminal's actual stdin is untouched
# the entire time - the same pattern Homebrew's own installer uses.
set -eu

log() { echo "workspaces-host-v2 install: $*" >&2; }
die() {
    echo "workspaces-host-v2 install: error: $*" >&2
    exit 1
}

: "${WORKSPACES_HOST_REPO:=$HOME/.workspaces-host-v2}"
: "${WORKSPACES_HOST_PROFILE:=current}"
# Some shells/environments don't export $USER even though `whoami`
# works (observed directly, not hypothetical) - the `current`/
# `current-<persona>` profiles need it for your real identity.
: "${USER:=$(whoami)}"
export USER WORKSPACES_HOST_REPO WORKSPACES_HOST_PROFILE

as_root() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    else
        sudo "$@"
    fi
}

# --- 1. Prerequisites (curl, git, xz) - auto-sensed per distro family --
# xz is easy to miss here: nothing above this line needs it, so a
# genuinely minimal image can get all the way to the Nix installer
# before it turns out to be missing - the Nix installer needs it to
# unpack its own binary tarball (`tar` alone can't decompress .tar.xz on
# Linux without it), a real gap hit directly on a fresh WSL Debian
# image, not a hypothetical one.
install_prereqs_linux() {
    if command -v curl >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v xz >/dev/null 2>&1; then
        log "curl, git, and xz already present"
        return
    fi
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    else
        ID=""
        ID_LIKE=""
    fi
    family=" ${ID:-} ${ID_LIKE:-} "
    case "$family" in
    *" debian "* | *" ubuntu "*)
        log "installing curl/git/xz via apt (Debian/Ubuntu family)"
        as_root apt-get update
        # The package is "xz-utils" on Debian/Ubuntu; it still provides
        # the "xz" binary the Nix installer actually looks for.
        as_root apt-get install -y curl git xz-utils
        ;;
    *" rhel "* | *" fedora "* | *" centos "*)
        log "installing curl/git/xz via dnf (RHEL/Fedora family)"
        as_root dnf install -y curl git xz
        ;;
    *" arch "*)
        log "installing curl/git/xz via pacman (Arch family)"
        as_root pacman -Sy --noconfirm curl git xz
        ;;
    *)
        die "unrecognized Linux distro (ID=${ID:-?} ID_LIKE=${ID_LIKE:-?}) - install curl, git, and xz yourself, then re-run this script"
        ;;
    esac
}

os=$(uname -s)
case "$os" in
Linux)
    install_prereqs_linux
    ;;
Darwin)
    command -v curl >/dev/null 2>&1 || die "curl not found - install the Xcode Command Line Tools (xcode-select --install) and re-run"
    command -v git >/dev/null 2>&1 || die "git not found - install the Xcode Command Line Tools (xcode-select --install) and re-run"
    # Ships with macOS itself, unlike Linux - checked anyway rather than
    # assumed, same as curl/git just above.
    command -v xz >/dev/null 2>&1 || die "xz not found - install it (e.g. 'brew install xz') and re-run"
    log "curl, git, and xz already present (macOS)"
    ;;
*)
    die "unsupported OS: $os - this installer covers Linux and macOS (see README's Installation section; on Windows, run this from inside WSL)"
    ;;
esac

# --- 2. Install Nix (single-user, idempotent) --------------------------
if command -v nix >/dev/null 2>&1; then
    log "Nix already installed"
else
    log "installing Nix (single-user - no systemd/daemon required)"
    nix_installer=$(mktemp)
    trap 'rm -f "$nix_installer"' EXIT
    curl -fsSL https://nixos.org/nix/install -o "$nix_installer"
    sh "$nix_installer" --no-daemon </dev/null
    rm -f "$nix_installer"
    trap - EXIT
fi

# Make `nix` usable in *this* script's shell right away, without
# requiring a new terminal window first.
for candidate in "$HOME/.nix-profile/etc/profile.d/nix.sh" "/etc/profile.d/nix.sh"; do
    if [ -f "$candidate" ]; then
        # shellcheck disable=SC1090
        . "$candidate"
        break
    fi
done
command -v nix >/dev/null 2>&1 || die "nix was installed but isn't on PATH yet - open a new terminal and re-run this script"

# --- 3. Enable flakes (idempotent - no duplicate lines on a re-run) ---
mkdir -p "$HOME/.config/nix"
if ! grep -q "experimental-features.*flakes" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
    log "enabling nix-command and flakes"
    echo "experimental-features = nix-command flakes" >>"$HOME/.config/nix/nix.conf"
fi

# --- 4. Clone (or update, if already cloned) this repo -----------------
if [ -d "$WORKSPACES_HOST_REPO/.git" ]; then
    log "updating existing clone at $WORKSPACES_HOST_REPO"
    git -C "$WORKSPACES_HOST_REPO" pull --ff-only
elif [ -e "$WORKSPACES_HOST_REPO" ]; then
    die "$WORKSPACES_HOST_REPO exists but isn't a git clone - move it aside, or set WORKSPACES_HOST_REPO to a different path and re-run"
else
    log "cloning to $WORKSPACES_HOST_REPO"
    git clone https://github.com/intellectual-frontiers/workspaces-host-v2.git "$WORKSPACES_HOST_REPO"
fi

# --- 5. Create the credentials file, if it doesn't exist yet -----------
# Same template `workspaces-host-update` would bootstrap on its own
# first run - done here too so it's already sitting there, ready to
# fill in, the moment this script finishes, rather than needing an
# extra "run workspaces-host-update once just to create it" round trip.
credentials_file="${XDG_CONFIG_HOME:-$HOME/.config}/workspaces-host/credentials"
if [ ! -f "$credentials_file" ]; then
    log "creating $credentials_file from the template"
    mkdir -p "$(dirname "$credentials_file")"
    cp "$WORKSPACES_HOST_REPO/credentials.example" "$credentials_file"
    chmod 600 "$credentials_file"
fi

# --- 6. Build and activate ----------------------------------------------
cd "$WORKSPACES_HOST_REPO"
log "building $WORKSPACES_HOST_PROFILE (downloads everything needed - can take a few minutes the first time)"
nix build ".#homeConfigurations.${WORKSPACES_HOST_PROFILE}.activationPackage" --impure
log "activating"
./result/activate

# --- 7. Make fish the actual login shell (best-effort) ------------------
# Home-manager standalone mode can't touch /etc/shells or /etc/passwd
# itself, so without this step activation alone leaves $SHELL as
# whatever it was before (bash, on a fresh Debian/WSL image) - fish only
# ever runs if you type "fish" yourself, every single new window,
# forever. `$HOME/.nix-profile/bin/fish` (not the raw /nix/store/...
# path underneath it) is the right chsh target: home-manager repoints
# that symlink atomically on every switch, so it keeps working across
# nixpkgs upgrades instead of going stale the moment fish's store path
# changes. Best-effort: a locked-down /etc (no sudo, a read-only
# filesystem, centrally-managed accounts) shouldn't fail the whole
# install - `fish` still works typed by hand either way, and `doctor`
# checks this so it's never a silent gap.
fish_path="$HOME/.nix-profile/bin/fish"
if [ -x "$fish_path" ]; then
    current_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)
    if [ "$current_shell" != "$fish_path" ]; then
        log "setting fish as your login shell"
        if grep -qxF "$fish_path" /etc/shells 2>/dev/null || as_root sh -c "echo '$fish_path' >> /etc/shells" 2>/dev/null; then
            if as_root chsh -s "$fish_path" "$USER" 2>/dev/null; then
                log "done - open a new terminal window (or WSL window) to see it take effect"
            else
                log "couldn't change your login shell automatically - run 'chsh -s $fish_path' yourself, or just type 'fish' each new window"
            fi
        else
            log "couldn't register fish in /etc/shells - run 'chsh -s $fish_path' yourself, or just type 'fish' each new window"
        fi
    fi
fi

log "done - open a new shell, then:"
log "  1. edit $credentials_file (your name/email, tokens, API keys) and run 'workspaces-host-update' to apply it - see README's 'Setting up your credentials' section"
log "  2. run 'doctor' to verify everything"
log "  3. (optional, recommended) see README's 'Fonts for the prompt icons' section for the last step"
