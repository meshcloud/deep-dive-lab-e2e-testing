{
  description = "Dev shell for the meshStack e2e-testing deep dive lab";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.opentofu
            pkgs.terragrunt
            pkgs.jq
          ];

          shellHook = ''
            echo "tofu $(tofu version | head -n1 | cut -d' ' -f2)  —  source bin/env.sh for the e2e chapters"
          '';
        };
      });
    };
}
