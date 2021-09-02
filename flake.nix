{
  description = "NixOps OVH plugin";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";
  inputs.nixops.url = "github:NixOS/nixops";

  outputs = { self, nixpkgs, flake-utils, poetry2nix, nixops }:
    {
      # Nixpkgs overlay providing the application
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev:
          let overrides = import ./overrides.nix { pkgs = prev; };
          in {
            nixops-ovh = prev.poetry2nix.mkPoetryApplication {
              projectDir = ./.;
              overrides = prev.poetry2nix.overrides.withDefaults overrides;
              meta.description =
                "NixOps OVH backend package for ${prev.stdenv.system}";
            };
          })
      ];
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in rec {
        defaultPackage = pkgs.nixops-ovh;
        defaultApp = apps.nixops-ovh;

        packages.nixops-ovh = pkgs.nixops-ovh;
        apps.nixops-ovh = flake-utils.lib.mkApp { drv = packages.nixops-ovh; };

        devShell = (pkgs.poetry2nix.mkPoetryEnv { projectDir = ./.; }).env;
      }));
}
