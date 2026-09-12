# Quickstart: Secrets Management

Both flows below were run for real during implementation (throwaway age
key, local-type rclone remote) - not hypothetical transcripts.

## 1. Declare and decrypt a secret

```console
$ age-keygen -o key.txt
Public key: age12fpd222j6y52xluqqj9f05l6k4wcvjzyd2e36mz0qltsv56j5geqkla4wq

$ export SOPS_AGE_KEY_FILE=./key.txt
$ echo -n "super-secret-value" | sops --encrypt --output-type yaml --age age12fpd... /dev/stdin > secret.enc.yaml
```

In your home-manager configuration:

```nix
workspacesHost.secrets.token = {
  sopsFile = ./secret.enc.yaml;
  path = "token";
};
```

```console
$ home-manager switch --flake .#default
...
Activating decryptWorkspacesHostSecrets
...

$ ls -la ~/.local/state/workspaces-host/secrets/
-rw------- 1 you you 18 ... token

$ cat ~/.local/state/workspaces-host/secrets/token
super-secret-value
```

The plaintext never appears in `/nix/store` - only `secret.enc.yaml`
(still encrypted) and the decrypt command itself are part of the built
activation package's closure.

**Correction (found and fixed while building feature 022's AI-harness
credentials, verified against real decrypted output rather than trusting
the command not to error):** `sops --decrypt` on a file produced by
`echo -n "value" | sops --encrypt ... /dev/stdin` returns the *whole
wrapper document* (`data: super-secret-value`), not the bare value -
`secretModule` now has an `extractKey` option, defaulting to `"data"`
(the key `sops` wraps unstructured stdin input under), which is why the
transcript above shows a clean bare value rather than a `token: ...`-
or `data: ...`-prefixed one. If you deliberately encrypt a multi-key
YAML/JSON file instead of a single bare value, set `extractKey = null;`
to get `sops`'s raw decrypted output as-is.

With no `workspacesHost.secrets` declared (the default), this module adds
no packages and no activation step - confirmed by diffing
`home.packages` before/after setting the option.

## 2. sensitivectl backup/restore

```console
$ cat ~/.config/rclone/rclone.conf
[myremote]
type = local

$ cat ~/.config/workspaces-host/sensitivectl.json
{
  "profiles": {
    "test-profile": {
      "local": "/home/you/Sensitive",
      "remote": "myremote:/backups/sensitive"
    }
  }
}

$ sensitivectl list
test-profile

$ sensitivectl backup test-profile
sensitivectl: backing up /home/you/Sensitive -> myremote:/backups/sensitive

$ rm -rf /home/you/Sensitive && mkdir /home/you/Sensitive
$ sensitivectl restore test-profile
sensitivectl: restoring myremote:/backups/sensitive -> /home/you/Sensitive
# content is back, byte-for-byte
```

Swap `type = local` for `type = s3`, `type = webdav`, etc. in
`rclone.conf` and the same `sensitivectl` commands work unchanged -
nothing in this tool is OneDrive- or provider-specific.
