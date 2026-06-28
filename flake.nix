{
  description = "A Flake for developing Vintage Story (game) Mods";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          pkgs,
          lib,
          system,
          ...
        }:
        {
          _module.args.pkgs = import self.inputs.nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (lib.getName pkg) [
                "vintagestory"
              ];
          };

          devShells = {
            default = pkgs.mkShell {
              nativeBuildInputs = with pkgs; [ dotnetCorePackages.sdk_10_0 ];
              env = {
                DOTNET_BIN = "${pkgs.dotnetCorePackages.sdk_10_0}/bin/dotnet";
                VINTAGE_STORY = "${pkgs.vintagestory}/share/vintagestory";
              };
            };
          };

          packages =
          let
            revision = self.shortRev or self.dirtyShortRev or "unknown";
             in
            {
            default = pkgs.vintagestory.overrideAttrs (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ (with pkgs; [ dotnetCorePackages.sdk_10_0 ]);
              
              src = ./.;
              srcs = old.src;
              
              unpackPhase = (old.unpackPhase or "") + ''
                cp "$src"/. indevMod -r
                tar -xf $srcs --strip-components=1
              '';

              buildPhase = (old.buildPhase or "") + ''
                cd indevMod/src
                dotnet build
                ls -lah
                cd ....
                ls -lah
              '';

              makeWrapperArgs = old.makeWrapperArgs ++ [
                '' --tracelog ''
                '' --addModPath "indevMod/src/bin/Debug/Mods" ''
                '' --addOrigin "indevMod/src/assets" ''
              ];
            });
          };
        };
    };
}
