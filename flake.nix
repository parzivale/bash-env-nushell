{
  description = "nu_plugin_bash_env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } {
      # fuck darwin
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      flake = {
      };

      perSystem = {
        pkgs,
        lib,
        ...
      }: {
        devShells.default = let
          inherit
            (pkgs)
            bash-env-json
            mkShell
            bashInteractive
            jq
            nushell
            ;
        in
          mkShell {
            nativeBuildInputs = [
              bash-env-json
              bashInteractive
              jq
              nushell
            ];
          };
        packages = {
          default =
            pkgs.stdenvNoCC.mkDerivation
            {
              name = "bash-env-nu";
              src = ./bash-env.nu;
              dontUnpack = true;
              preferLocalBuild = true;
              allowSubstitutes = false;

              installPhase = ''
                runHook preBuild
                mkdir -p "$out/bin"
                substitute "$src" "$out/bin/bash-env.nu" --replace-fail ${lib.escapeShellArg "bash-env-json"} ${lib.escapeShellArg "${pkgs.bash-env-json}/bin/bash-env-json"}
                chmod +x "$out/bin/bash-env.nu"
                runHook postBuild
              '';

              meta.mainProgram = "bash-env.nu";
            };
        };
      };
    };
}
