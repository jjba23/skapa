{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs = { systems, nixpkgs, ... }:
    let
      eachSystem = f:
        nixpkgs.lib.genAttrs (import systems)
        (system: f nixpkgs.legacyPackages.${system});
    in {
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            scala_3
            jdk25
            metals
            sbt
            scalafmt
            scalafix
            scala-cli
            coursier
          ];
        };
      });
    };
}
