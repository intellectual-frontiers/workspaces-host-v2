{ pkgs, ... }:

{
  # Data engineering/analysis: a Python toolchain and a local analytical
  # database, on top of the shared base profile.
  home.packages = with pkgs; [
    python3
    uv
    duckdb
  ];
}
