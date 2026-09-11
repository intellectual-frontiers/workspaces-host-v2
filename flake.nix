{
  description = "Workspaces Host v2 - core flake: home-manager module (fish, oh-my-posh, direnv, git), ported CLI tools, and an OCI image built from the same closure";

  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-24.11&shallow=1";

    home-manager = {
      url = "git+https://github.com/nix-community/home-manager?ref=release-24.11&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      # Manual per-system iteration rather than a flake-utils dependency:
      # keeps this flake's own input set minimal and avoids an extra
      # transitive fetch for a handful of lines of boilerplate.
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };

      mkHomeConfiguration = system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            ./home
            {
              # Example/default identity - override per-user by forking
              # this module set; see quickstart.md.
              home.username = "workspace";
              home.homeDirectory =
                if nixpkgs.lib.hasSuffix "darwin" system
                then "/Users/workspace"
                else "/home/workspace";
              home.stateVersion = "24.11";
            }
          ];
        };

      # Computed once per system so `packages`, `homeConfigurations`, and
      # `checks` all build the OCI image and the activation package from
      # the exact same evaluated home-manager config (Constitution
      # Principle IV: host and container share one closure).
      homeConfigurationsFor = forAllSystems mkHomeConfiguration;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          ported = import ./pkgs { inherit pkgs; };
        in
        ported // {
          oci-image = import ./oci {
            inherit pkgs;
            homeConfig = homeConfigurationsFor.${system};
          };
        }
      );

      # One home-manager profile per supported system, so `nix flake check`
      # and CI can build every platform. `default` aliases the profile for
      # this repo's primary target (x86_64-linux); engineers on another
      # platform use that system's own name instead of `default`
      # (see specs/001-core-flake-home-manager/quickstart.md).
      homeConfigurations = homeConfigurationsFor // {
        default = homeConfigurationsFor.x86_64-linux;
      };

      checks = forAllSystems (system: {
        default = homeConfigurationsFor.${system}.activationPackage;
      });
    };
}
