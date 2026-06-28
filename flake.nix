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

          packages = {config, ...}:
          let
            projectName = "vs-levels";
            revision = "0.1"; #self.shortRev or self.dirtyShortRev or "unknown";
            srcFolder = ./src;
             in
            {
            default = pkgs.buildDotnetModule {
              pname = projectName;
              version = revision;
              src = srcFolder;

              nativeBuildInputs = [
                (lib.getBin pkgs.vintagestory)
              ];

              env = {
                VINTAGE_STORY = "${pkgs.vintagestory}/share/vintagestory";
              };

              projectFile = "./${projectName}.csproj";
              nugetDeps = ./src/deps.json; # update with `nix build .#default.fetch-deps`

              dotnet-sdk = pkgs.dotnetCorePackages.sdk_10_0;
              dotnet-runtime = pkgs.dotnetCorePackages.runtime_10_0;

              executables = [];
              packnupkg = false;

              # desktopItem = [
              #   (pkgs.makeDesktopItem {
              #     name = "vintagestory-indev";
              #     desktopName = "Vintage Story w/indevMods";
              #     exec = "${pkgs.vintagestory} --tracelog --addModPath \"${config.packages.default}/lib\" ";
              #     icon = "vintagestory";
              #     comment = "Innovate and explore in a sandbox world";
              #     categories = [ "Game" ];
              #   })
              # ];
            };
          };
        };
    };
}
