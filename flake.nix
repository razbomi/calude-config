{
  description = "Native Claude Code, packaged with Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      overlays.default = final: _prev: {
        claude-code = final.callPackage ./package.nix { };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          claude-code = pkgs.callPackage ./package.nix { };
          default = claude-code;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          update = pkgs.writeShellScript "update-claude-pin" ''
            export PATH=${nixpkgs.lib.makeBinPath [
              pkgs.curl
              pkgs.jq
              pkgs.coreutils
            ]}:$PATH
            exec ${pkgs.bash}/bin/bash ${./update.sh} "$@"
          '';
        in
        {
          update = {
            type = "app";
            program = "${update}";
          };
        }
      );
    };
}
