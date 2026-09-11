{ ... }:

{
  programs.direnv = {
    enable = true;
    # enableFishIntegration is read-only (always on) in this home-manager
    # version: direnv's own package auto-loads its Fish integration.

    nix-direnv.enable = true;
  };
}
