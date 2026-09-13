{ pkgs, ... }:

let
  ported = import ../pkgs { inherit pkgs; };

  # nixpkgs' cnquery fetches its source with fetchFromGitHub, a sandboxed
  # fixed-output derivation build - the same class of problem
  # pkgs/specify-cli/default.nix's own comment documents (a sandbox whose
  # egress proxy the *build sandbox's* curl can't TLS-validate the way
  # the outer `nix` CLI process can). builtins.fetchGit, evaluated by
  # that outer process, sidesteps it the same way; vendorHash is
  # untouched since the fetched tree is byte-identical to the tagged
  # release archive.
  cnquery' = pkgs.cnquery.overrideAttrs (_old: {
    src = builtins.fetchGit {
      url = "https://github.com/mondoohq/cnquery";
      rev = "7dee6bd537cb4a04c223a19394726fa8707171e6"; # v11.19.1
    };
  });
in
{
  home.packages = (builtins.attrValues ported) ++ (with pkgs; [
    ripgrep
    fd
    jq
    bat
    eza
    gitleaks
    # A few more modern, Rust-based replacements for classic CLI tools -
    # available under their own names (nothing here is aliased over a
    # POSIX builtin except `ls`/`cat`, in home/shell.nix's
    # shellAliases), so tutorials/scripts using the originals keep
    # working, while anyone who wants the nicer version just has to type
    # its name once to discover it exists.
    bottom # `btm` - a friendlier top/htop, no config needed to be useful
    du-dust # `dust` - du, but shows what's actually taking up space at a glance
    tealdeer # `tldr` - short, example-driven command help instead of a full man page
    # a terminal multiplexer with a visible on-screen keybinding hint
    # bar - much more discoverable than tmux's own for anyone who's
    # never used either
    zellij
    # bash's own syntax-highlighting/autosuggestion engine (see
    # home/shell.nix) - listed here too so `blesh-share`/`ble-update` are
    # on PATH for manual use, not just the one file shell.nix sources
    # directly by store path
    blesh
    # `ssh`/`ssh-keygen` - most base OS images already have these, but
    # this repo doesn't rely on that: `doctor`'s SSH-key check (pkgs/doctor)
    # tells engineers to run `ssh-keygen` if they don't have one, so the
    # tool itself needs to actually be here, hermetically, not assumed.
    openssh
    # GitHub/GitLab CLIs - `doctor` (pkgs/doctor) checks their auth
    # status, since that's the actual, checkable signal that credentials
    # are set up correctly (a token file could exist and still be
    # expired/revoked; `gh auth status`/`glab auth status` catch that).
    gh
    glab
    # Compliance/observability tooling (see README's "Compliance &
    # observability tooling" section) - plain nixpkgs packages, so they
    # flow in here directly rather than through pkgs/default.nix's
    # aggregate of this repo's own custom-built tools.
    steampipe
    openobserve
  ] ++ [ cnquery' ])
  # Bulk multi-repo git tooling (see README's "Bulk changes across many
  # repos" section, near mgit) - a plain nixpkgs package, so it flows in
  # here directly rather than through pkgs/default.nix's aggregate of
  # this repo's own custom-built tools (git-xargs, alongside it, isn't in
  # nixpkgs and is one of those - see pkgs/git-xargs). git-extras bundles
  # its own `bin/git-standup`, which collides with this repo's own,
  # already-ported `pkgs/git-standup` - lowPrio makes that one lose the
  # collision rather than failing the build; every other git-extras
  # subcommand is unaffected.
  ++ [ (pkgs.lib.lowPrio pkgs.git-extras) ]
  # osquery is nixpkgs-packaged Linux-only (meta.platforms = platforms.linux
  # at pkgs/tools/system/osquery) - unlike cnquery/steampipe/openobserve
  # above, referencing it unconditionally would fail to evaluate
  # home.packages on Darwin, so it's added only where it actually builds,
  # the same reasoning pkgs/default.nix documents for excluding
  # init-firewall from its aggregate.
  ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.osquery;
}
