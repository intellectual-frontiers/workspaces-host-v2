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
      extractKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "data";
        description = ''
          Which top-level key to pull the bare value from before writing
          it out. `sops --encrypt` wraps unstructured input (e.g.
          `echo -n "value" | sops --encrypt ... /dev/stdin`, the pattern
          README documents for tokens/API keys) under a `data` key - a
          plain `sops --decrypt` on that file returns the *whole
          document* (literally `data: value`), not the bare value, which
          silently produces a broken `export
          FOO=$(cat decrypted-file)` (a real bug, caught by testing this
          module's actual decrypted output rather than trusting the
          command not to error). Defaulting this to `"data"` makes the
          common case - one secret, one file, used as a bare value -
          correct out of the box. Set to `null` if you deliberately
          encrypted a multi-key file and want sops's raw decrypted
          output (e.g. full YAML/JSON) instead of one extracted field.
        '';
      };
    };
  };

  secretsStateDir = "${config.xdg.stateHome}/workspaces-host/secrets";

  decryptOne = name: secret:
    let
      extractArg = lib.optionalString (secret.extractKey != null)
        ''--extract '["${secret.extractKey}"]' '';
    in
    ''
      mkdir -p "$(dirname "${secretsStateDir}/${secret.path}")"
      ${pkgs.sops}/bin/sops --decrypt ${extractArg}"${secret.sopsFile}" > "${secretsStateDir}/${secret.path}.tmp"
      chmod 600 "${secretsStateDir}/${secret.path}.tmp"
      mv "${secretsStateDir}/${secret.path}.tmp" "${secretsStateDir}/${secret.path}"
    '';
in
{
  options.workspacesHost.secrets = lib.mkOption {
    type = lib.types.attrsOf secretModule;
    default = { };
    description = ''
      Declarative, *advanced*, sops-encrypted secrets - for anyone who
      specifically wants field-level encryption at rest for a given
      credential. Most people don't need this: see
      `~/.config/workspaces-host/credentials` and `workspaces-host-update`
      (README's "Setting up your credentials" section) for the
      recommended default - a plain `KEY=value` file, protected by
      ordinary file permissions, with no `age`/`sops` steps at all.

      Each secret declared here is decrypted at *activation* time
      (`home-manager switch`, every run - never at build/eval time) into
      `$XDG_STATE_HOME/workspaces-host/secrets/`, so the plaintext never
      lands in the world-readable Nix store. Decryption uses whatever
      key `sops` itself is configured to find (age key at
      `$XDG_CONFIG_HOME/sops/age/keys.txt` by convention, or a PGP key in
      the ambient keyring) - this module intentionally does not manage
      key material itself, per Constitution Principle III ("secrets
      never touch the agent's shell unscoped"): provisioning the
      decryption key is a deliberate, separate, human action.
    '';
    example = lib.literalExpression ''
      {
        "github-token" = {
          sopsFile = ./secrets/github-token.enc.yaml;
          path = "env/GITHUB_TOKEN";
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
