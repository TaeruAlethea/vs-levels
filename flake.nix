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
          config,
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
              modinfo = builtins.fromJSON (builtins.readFile ./src/modinfo.json);
            in
            {
              default = pkgs.buildDotnetModule {
                pname = modinfo.modid;
                version = modinfo.version;
                src = ./src;

                nativeBuildInputs = [
                  (lib.getBin pkgs.vintagestory)
                ];

                env = {
                  VINTAGE_STORY = "${pkgs.vintagestory}/share/vintagestory";
                };

                projectFile = "./${modinfo.modid}.csproj";
                nugetDeps = ./src/deps.json; # update with `nix build .#default.fetch-deps`

                dotnet-sdk = pkgs.dotnetCorePackages.sdk_10_0;
                dotnet-runtime = pkgs.dotnetCorePackages.runtime_10_0;

                fixupPhase = ''
                  mkdir -p "$out/bin"
                  echo '#!${pkgs.bash}/bin/bash' > $out/bin/${modinfo.modid}
                  echo "${lib.getExe pkgs.vintagestory} --tracelog --addModPath $out/lib" >> $out/bin/${modinfo.modid}
                  chmod +x "$out/bin/${modinfo.modid}"
                '';

                executables = [ ];
                packnupkg = false;
              };
            };
        };
    };
}
