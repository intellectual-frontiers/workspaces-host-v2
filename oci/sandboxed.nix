{ pkgs, homeConfig }:

let
  cfg = homeConfig.config;
  configFile = name: cfg.xdg.configFile.${name}.source;

  agentUid = "1000";
  agentGid = "1000";

  passwd = pkgs.writeTextDir "etc/passwd" ''
    root:x:0:0::/root:/bin/sh
    agent:x:${agentUid}:${agentGid}::/home/agent:/bin/sh
    nobody:x:65534:65534::/var/empty:/bin/sh
  '';
  group = pkgs.writeTextDir "etc/group" ''
    root:x:0:
    agent:x:${agentGid}:
    nobody:x:65534:
  '';
  nsswitch = pkgs.writeTextDir "etc/nsswitch.conf" ''
    hosts: files dns
  '';

  entrypoint = pkgs.writeShellApplication {
    name = "sandboxed-entrypoint";
    runtimeInputs = [
      (import ../pkgs/init-firewall { inherit pkgs; })
      pkgs.util-linux
    ];
    text = builtins.readFile ./sandboxed-entrypoint.sh;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "workspaces-host-sandboxed";
  tag = "latest";

  contents = cfg.home.packages ++ (with pkgs; [
    bashInteractive
    coreutils
    cacert
    iptables
    ipset
    util-linux
    entrypoint
    passwd
    group
    nsswitch
  ]);

  extraCommands = ''
    mkdir -p home/agent/.config/fish home/agent/.config/git home/agent/.config/oh-my-posh home/agent/.config/direnv/lib root tmp
    cp ${configFile "fish/config.fish"} home/agent/.config/fish/config.fish
    cp ${configFile "git/config"} home/agent/.config/git/config
    cp ${configFile "oh-my-posh/config.json"} home/agent/.config/oh-my-posh/config.json
    cp ${configFile "direnv/lib/hm-nix-direnv.sh"} home/agent/.config/direnv/lib/hm-nix-direnv.sh
    chmod -R u+w home root
  '';

  config = {
    Env = [
      "HOME=/home/agent"
      "USER=agent"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    Entrypoint = [ "${entrypoint}/bin/sandboxed-entrypoint" ];
    WorkingDir = "/home/agent";
  };
}
