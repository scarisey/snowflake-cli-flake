{
  description = "A Nix flake for the Snowflake CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {inherit system;pkgs=(import nixpkgs {inherit system;});});
    in {
      packages =  forAllSystems ({system,pkgs}: {
        default = pkgs.callPackage ./package.nix {};
      });
      devShells = forAllSystems ({system,pkgs}:
        {
          updateShell = pkgs.mkShell {
            packages = [
              pkgs.curl
              pkgs.jq
              pkgs.nix
              pkgs.gnused
            ];
            shellHook = ''
              echo "🔄 Update environment loaded"
              echo "Run './update.sh' to check for and apply updates to snowflake-cli"
            '';
          };
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.default
            ];

            shellHook = ''
                echo ${self.packages.${system}.default}
                echo "✅ 'snow' command is now available."
            '';
            NIX_SHELL_PRESERVE_ENVIRONMENT = [ "HOME" ];
          };
        }
      );
    };
}
