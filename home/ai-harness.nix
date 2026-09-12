{ pkgs, ... }:

{
  # AI-assisted CLI tooling, so an AI harness can help configure this
  # sandbox itself right after install (edit local.nix, declare a
  # secret, etc.), not just help with application code.
  #
  # `aider-chat` is genuinely packaged in this flake's pinned nixpkgs and
  # provider-agnostic (works with Claude, GPT, Gemini, ... via whichever
  # API key you export), so it's installed directly here, the same as
  # every other tool in this repo.
  #
  # Claude Code (`@anthropic-ai/claude-code`), OpenAI's Codex CLI
  # (`@openai/codex`), and Google's Gemini CLI (`@google/gemini-cli`)
  # are NOT Nix-packaged here on purpose: they ship near-weekly releases,
  # and hand-vendoring each one as a `buildNpmPackage` derivation would
  # mean either pinning to a stale version indefinitely or re-deriving a
  # new npm hash on every release - a maintenance burden this repo isn't
  # taking on for tools whose whole value is being current. `nodejs`
  # (their shared runtime) is provisioned here instead, so installing the
  # actual CLI is just the one `npm install -g` command upstream already
  # documents - see README's "Setting up AI harness credentials" section
  # for the exact commands and, more importantly, the safe way to give
  # each one its API key without ever putting it in a tracked file.
  home.packages = [
    pkgs.nodejs
    pkgs.aider-chat
  ];
}
