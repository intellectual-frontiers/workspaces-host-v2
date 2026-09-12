{ pkgs, ... }:

let
  ported = import ../pkgs { inherit pkgs; };
in
{
  home.packages = (builtins.attrValues ported) ++ (with pkgs; [
    ripgrep
    fd
    jq
    bat
    eza
    fzf
    gitleaks
  ])
  # Bulk multi-repo git tooling (see README's "Bulk changes across many
  # repos" section, near mgit) - a plain nixpkgs package, so it flows in
  # here directly rather than through pkgs/default.nix's aggregate of
  # this repo's own custom-built tools (git-xargs, alongside it, isn't in
  # nixpkgs and is one of those - see pkgs/git-xargs). git-extras bundles
  # its own `bin/git-standup`, which collides with this repo's own,
  # already-ported `pkgs/git-standup` - lowPrio makes that one lose the
  # collision rather than failing the build; every other git-extras
  # subcommand is unaffected.
  ++ [ (pkgs.lib.lowPrio pkgs.git-extras) ];
}
