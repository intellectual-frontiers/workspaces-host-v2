{ pkgs, ... }:

{
  # The original repo used SDKMAN! to install a JDK (Amazon Corretto) and
  # Maven per-engineer, opt-in, via a `setup-java-amazon-corretto` fish
  # function. In a Nix-first repo, a second version manager on top of Nix
  # itself would just be two tools doing the same job - the flake's own
  # pin (nixpkgs 24.11 here) is already the reproducible "version manager"
  # for every tool this repo provides, Java included. So this installs a
  # JDK + Maven directly from nixpkgs, unconditionally, like every other
  # ported tool, rather than a version manager an engineer has to
  # separately invoke.
  home.packages = [
    pkgs.jdk
    pkgs.maven
  ];

  home.sessionVariables.JAVA_HOME = "${pkgs.jdk.home}";
}
