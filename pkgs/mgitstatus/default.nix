{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "mgitstatus";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./mgitstatus} $out/bin/mgitstatus
    wrapProgram $out/bin/mgitstatus \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.git pkgs.findutils pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Report git status (dirty/ahead/behind/no-upstream) across every repo under one or more directories";
    mainProgram = "mgitstatus";
  };
}
