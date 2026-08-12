{
  description = "Interactive CLI wizard project scaffolder in Guile Scheme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.callPackage ./default.nix { };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            guile
            guile-json
            coreutils
            util-linux
          ];

          shellHook = ''
            export GUILE_LOAD_PATH="$PWD/src:$GUILE_LOAD_PATH"
            echo "🔮 Skapa Guile development environment ready."
          '';
        };

        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      }
    );
}
