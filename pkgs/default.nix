{ pkgs }:

{
  semtag = import ./semtag { inherit pkgs; };
  mgitstatus = import ./mgitstatus { inherit pkgs; };
  mgit = import ./mgit { inherit pkgs; };
  pgpass = import ./pgpass { inherit pkgs; };
  workspaces-host-update = import ./workspaces-host-update { inherit pkgs; };
  git-standup = import ./git-standup { inherit pkgs; };
  git-xargs = import ./git-xargs { inherit pkgs; };
  specify-cli = import ./specify-cli { inherit pkgs; };
  backlog-md = import ./backlog-md { inherit pkgs; };
  scaffold-agent-harness = import ./scaffold-agent-harness { inherit pkgs; };
  sensitivectl = import ./sensitivectl { inherit pkgs; };
  doctor = import ./doctor { inherit pkgs; };
  # init-firewall is deliberately NOT included here: it depends on
  # iptables/ipset, which nixpkgs marks unsupported (meta.badPlatforms)
  # on Darwin, and this aggregate feeds every profile's home.packages
  # across all four systems. It's a Linux-only, container-sandboxing
  # concern - see flake.nix's Linux-only `packages.<system>` addition and
  # oci/sandboxed.nix, which imports ./init-firewall directly.
}
