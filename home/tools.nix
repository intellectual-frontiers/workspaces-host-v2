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
    fzf
    # Compliance/observability tooling (see README's "Compliance &
    # observability tooling" section) - plain nixpkgs packages, so they
    # flow in here directly rather than through pkgs/default.nix's
    # aggregate of this repo's own custom-built tools.
    steampipe
    openobserve
  ] ++ [ cnquery' ])
  # osquery is nixpkgs-packaged Linux-only (meta.platforms = platforms.linux
  # at pkgs/tools/system/osquery) - unlike cnquery/steampipe/openobserve
  # above, referencing it unconditionally would fail to evaluate
  # home.packages on Darwin, so it's added only where it actually builds,
  # the same reasoning pkgs/default.nix documents for excluding
  # init-firewall from its aggregate.
  ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.osquery;
}
