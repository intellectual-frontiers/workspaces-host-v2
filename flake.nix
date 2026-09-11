{
  description = "Workspaces Host v2 - core flake: home-manager module (fish, oh-my-posh, direnv, git), ported CLI tools, per-persona profiles, and an OCI image built from the same closure";

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

      # Per-persona profiles (Phase 6): each adds a small, focused package
      # set on top of the shared base (home/) - replacing the old repo's
      # single global Homebrew package list with composable slices.
      personaModules = {
        backend = ./home/profiles/backend.nix;
        data = ./home/profiles/data.nix;
        mobile = ./home/profiles/mobile.nix;
        agent-ops = ./home/profiles/agent-ops.nix;
      };

      mkHomeConfiguration = system: extraModules:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            ./home
          ] ++ extraModules ++ [
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
      homeConfigurationsFor = forAllSystems (system: mkHomeConfiguration system [ ]);

      # Persona configurations are pinned to x86_64-linux, same rationale
      # as `default` below: engineers on another platform substitute that
      # system's own attribute (or fork a persona module for their
      # platform) rather than this flake enumerating every
      # persona x system combination up front.
      personaConfigurations = nixpkgs.lib.mapAttrs
        (_name: modulePath: mkHomeConfiguration "x86_64-linux" [ modulePath ])
        personaModules;
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
        # init-firewall (iptables/ipset) declares itself unsupported on
        # Darwin at the nixpkgs level (meta.badPlatforms), which fails
        # *evaluation*, not just building - unlike oci-image, this pair
        # can't even be listed as a package attribute on those systems.
        // nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "linux" system) {
          init-firewall = import ./pkgs/init-firewall { inherit pkgs; };
          oci-image-sandboxed = import ./oci/sandboxed.nix {
            inherit pkgs;
            homeConfig = homeConfigurationsFor.${system};
          };
        }
      );

      # One home-manager profile per supported system, so `nix flake check`
      # and CI can build every platform. `default` aliases the profile for
      # this repo's primary target (x86_64-linux); engineers on another
      # platform use that system's own name instead of `default`
      # (see specs/001-core-flake-home-manager/quickstart.md). The named
      # persona profiles (backend/data/mobile/agent-ops - Phase 6) layer a
      # focused extra package set on top of that same base.
      homeConfigurations = homeConfigurationsFor // personaConfigurations // {
        default = homeConfigurationsFor.x86_64-linux;
      };

      checks = forAllSystems (system: {
        default = homeConfigurationsFor.${system}.activationPackage;
      });
    };
}
