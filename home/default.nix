{ pkgs, ... }:

let
  # The one supported place for personal overrides (git identity, real
  # `workspacesHost.secrets` declarations, persona/tool tweaks) - see
  # local.nix.example at the repo root and README's "Updating your Git
  # identity, and other secrets, from the CLI" section. Deliberately
  # OUTSIDE this repo's own directory (not just .gitignore'd inside it):
  # a flake evaluated from a git checkout only ever sees git-tracked
  # files, even with `--impure` and even for a file that's merely
  # gitignored-but-present on disk, so a local override file has to live
  # somewhere Nix reads directly off the filesystem instead - only
  # possible impurely, which is why this silently does nothing (no
  # error) under `nix flake check`'s pure evaluation: `default`, every
  # per-system profile, and the persona profiles just don't have one.
  # `/. + string` coerces the dynamically-computed string into an actual
  # Nix path value - a bare string in `imports` confuses the module
  # system (observed as an infinite-recursion error resolving `pkgs` as
  # a module arg), since `imports` entries must be real paths or modules.
  localConfigPath = /. + (builtins.getEnv "HOME" + "/.config/workspaces-host/local.nix");
in
{
  imports = [
    ./shell.nix
    ./direnv.nix
    ./git.nix
    ./tools.nix
    ./secrets.nix
    ./fonts.nix
    ./workspaces.nix
    ./postgres.nix
    ./java.nix
    ./ai-harness.nix
  ] ++ (if builtins.pathExists localConfigPath then [ localConfigPath ] else [ ]);

  # home.username, home.homeDirectory, and home.stateVersion are supplied by
  # the caller (see flake.nix's mkHomeConfiguration) so this module set stays
  # reusable across profiles (Phase 6 will add more callers on top of it).

  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;
}
