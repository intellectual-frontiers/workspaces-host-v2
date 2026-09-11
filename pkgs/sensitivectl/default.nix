{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "sensitivectl";
  version = "1.0.0";
  src = ./.;
  dontUnpack = true;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${./sensitivectl} $out/bin/sensitivectl
    wrapProgram $out/bin/sensitivectl \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.rclone pkgs.jq pkgs.coreutils ]}
    runHook postInstall
  '';

  meta = {
    description = "Backup/restore named local directories to/from rclone remotes, config-driven (generalizes the old coach-sensitivectl over any rclone remote, not just OneDrive)";
    mainProgram = "sensitivectl";
  };
}
