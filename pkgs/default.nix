{ pkgs }:

{
  semtag = import ./semtag { inherit pkgs; };
  mgitstatus = import ./mgitstatus { inherit pkgs; };
  git-standup = import ./git-standup { inherit pkgs; };
}
