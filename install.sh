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

# --- 1. Prerequisites (curl, git) - auto-sensed per distro family -----
install_prereqs_linux() {
    if command -v curl >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
        log "curl and git already present"
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
        log "installing curl/git via apt (Debian/Ubuntu family)"
        as_root apt-get update
        as_root apt-get install -y curl git
        ;;
    *" rhel "* | *" fedora "* | *" centos "*)
        log "installing curl/git via dnf (RHEL/Fedora family)"
        as_root dnf install -y curl git
        ;;
    *" arch "*)
        log "installing curl/git via pacman (Arch family)"
        as_root pacman -Sy --noconfirm curl git
        ;;
    *)
        die "unrecognized Linux distro (ID=${ID:-?} ID_LIKE=${ID_LIKE:-?}) - install curl and git yourself, then re-run this script"
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
    log "curl and git already present (macOS)"
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

# --- 5. Build and activate ----------------------------------------------
cd "$WORKSPACES_HOST_REPO"
log "building $WORKSPACES_HOST_PROFILE (downloads everything needed - can take a few minutes the first time)"
nix build ".#homeConfigurations.${WORKSPACES_HOST_PROFILE}.activationPackage" --impure
log "activating"
./result/activate

log "done - open a new shell, then:"
log "  1. run 'workspaces-host-update' to set up your git identity, GitHub/GitLab tokens, and AI harness API keys (README's 'Setting up your credentials' section)"
log "  2. run 'doctor' to verify everything"
log "  3. (optional, recommended) see README's 'Fonts for the prompt icons' section for the last step"
