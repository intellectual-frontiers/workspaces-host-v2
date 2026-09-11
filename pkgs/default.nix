{ pkgs }:

{
  semtag = import ./semtag { inherit pkgs; };
  mgitstatus = import ./mgitstatus { inherit pkgs; };
  git-standup = import ./git-standup { inherit pkgs; };
  specify-cli = import ./specify-cli { inherit pkgs; };
  backlog-md = import ./backlog-md { inherit pkgs; };
  scaffold-agent-harness = import ./scaffold-agent-harness { inherit pkgs; };
  sensitivectl = import ./sensitivectl { inherit pkgs; };
}
