{ pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./direnv.nix
    ./git.nix
    ./tools.nix
    ./secrets.nix
  ];

  # home.username, home.homeDirectory, and home.stateVersion are supplied by
  # the caller (see flake.nix's mkHomeConfiguration) so this module set stays
  # reusable across profiles (Phase 6 will add more callers on top of it).

  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;
}
