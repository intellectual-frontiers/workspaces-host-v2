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
  ]);
}
