{ pkgs, homeConfig }:

let
  cfg = homeConfig.config;
  configFile = name: cfg.xdg.configFile.${name}.source;
in
pkgs.dockerTools.buildLayeredImage {
  name = "workspaces-host";
  tag = "latest";

  # Same closure as the host profile: the exact package set home-manager
  # decided this profile needs (fish, oh-my-posh, direnv, git, the ported
  # scripts, and the core CLI toolset), plus cacert/bash/coreutils for a
  # usable minimal container.
  contents = cfg.home.packages ++ (with pkgs; [
    bashInteractive
    coreutils
    cacert
    dockerTools.fakeNss
  ]);

  extraCommands = ''
    mkdir -p root/.config/fish root/.config/git root/.config/oh-my-posh root/.config/direnv/lib tmp
    cp ${configFile "fish/config.fish"} root/.config/fish/config.fish
    cp ${configFile "git/config"} root/.config/git/config
    cp ${configFile "oh-my-posh/config.json"} root/.config/oh-my-posh/config.json
    cp ${configFile "direnv/lib/hm-nix-direnv.sh"} root/.config/direnv/lib/hm-nix-direnv.sh
    chmod -R u+w root
  '';

  config = {
    Env = [
      "HOME=/root"
      "USER=root"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    Cmd = [ "${pkgs.fish}/bin/fish" ];
    WorkingDir = "/root";
  };
}
