{ config, lib, pkgs, ... }:

let
  cfg = config.workspacesHost.secrets;

  secretModule = lib.types.submodule {
    options = {
      sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the sops-encrypted file holding this secret.";
      };
      path = lib.mkOption {
        type = lib.types.str;
        description = ''
          Where to write the decrypted plaintext, relative to
          `$XDG_STATE_HOME/workspaces-host/secrets` (never inside the Nix
          store, never world-readable - written at activation time, not
          build time).
        '';
      };
    };
  };

  secretsStateDir = "${config.xdg.stateHome}/workspaces-host/secrets";

  decryptOne = name: secret: ''
    mkdir -p "$(dirname "${secretsStateDir}/${secret.path}")"
    ${pkgs.sops}/bin/sops --decrypt "${secret.sopsFile}" > "${secretsStateDir}/${secret.path}.tmp"
    chmod 600 "${secretsStateDir}/${secret.path}.tmp"
    mv "${secretsStateDir}/${secret.path}.tmp" "${secretsStateDir}/${secret.path}"
  '';
in
{
  options.workspacesHost.secrets = lib.mkOption {
    type = lib.types.attrsOf secretModule;
    default = { };
    description = ''
      Declarative sops-encrypted secrets. Each is decrypted at
      *activation* time (`home-manager switch`, every run - never at
      build/eval time) into `$XDG_STATE_HOME/workspaces-host/secrets/`,
      so the plaintext never lands in the world-readable Nix store.
      Decryption uses whatever key `sops` itself is configured to find
      (age key at `$XDG_CONFIG_HOME/sops/age/keys.txt` by convention, or
      a PGP key in the ambient keyring) - this module intentionally does
      not manage key material itself, per Constitution Principle III
      ("secrets never touch the agent's shell unscoped"): provisioning
      the decryption key is a deliberate, separate, human action.
    '';
    example = lib.literalExpression ''
      {
        "github-token" = {
          sopsFile = ./secrets/github-token.enc.yaml;
          path = "github-token";
        };
      }
    '';
  };

  config = lib.mkIf (cfg != { }) {
    home.packages = [ pkgs.sops pkgs.age ];

    # Raw bash rather than home-manager's `run` helper: `run` executes its
    # argument list as a single command (no shell interpretation), but
    # decrypting each secret is itself a short multi-statement pipeline.
    home.activation.decryptWorkspacesHostSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${secretsStateDir}"
      chmod 700 "${secretsStateDir}"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList decryptOne cfg)}
    '';
  };
}
