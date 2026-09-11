{ pkgs, ... }:

{
  # Agent-ops: operating GitHub-hosted CI/PR workflows and running GitHub
  # Actions locally, for engineers whose day-to-day is driving AI coding
  # agents against real repositories rather than writing application code
  # directly. specify/backlog-md/scaffold-agent-harness are already in
  # the shared base profile (Phase 3) - this adds what's specific to
  # this persona.
  home.packages = with pkgs; [
    gh
    act
  ];
}
