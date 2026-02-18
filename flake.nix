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
        "aarch64-darwin"
      ];
      flake = {
      };

      perSystem = {
        pkgs,
        lib,
        self',
        ...
      }: let
        inherit
          (pkgs)
          bash-env-json
          bashInteractive
          jq
          nushell
          ;
        testDeps = [
          bash-env-json
          bashInteractive
          jq
          nushell
        ];
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = testDeps;
        };

        checks = {
          tests = pkgs.stdenvNoCC.mkDerivation {
            name = "bash_env_tests";
            src = ./.;
            nativeBuildInputs = testDeps;
            dontBuild = true;
            doCheck = true;
            checkPhase = ''
              nu --no-config-file --no-history -c '
                use std/testing *
                source tests.nu
                let test_cmds = (scope commands | where attributes.0?.name? == "test" | get name)
                for cmd in $test_cmds {
                  print -n $"Testing: ($cmd) ... "
                  let result = do { nu --no-config-file --no-history -c $"use std/testing *\nuse std/assert\nuse bash-env.nu\nsource tests.nu\n($cmd)" } | complete
                  if $result.exit_code == 0 {
                    print "OK"
                  } else {
                    print $"FAILED\n($result.stderr)"
                    exit 1
                  }
                }
                print "All tests passed"
              '
            '';
            installPhase = ''
              touch $out
            '';
          };

          package = self'.packages.default;
        };

        packages = {
          default =
            pkgs.stdenvNoCC.mkDerivation
            {
              name = "nu_plugin_bash_env";
              src = ./bash-env.nu;
              dontUnpack = true;
              preferLocalBuild = true;
              allowSubstitutes = false;

              installPhase = ''
                runHook preBuild
                mkdir -p "$out/bin"
                substitute "$src" "$out/bin/plugin_nu_bash_env" --replace-fail ${lib.escapeShellArg "bash-env-json"} ${lib.escapeShellArg "${pkgs.bash-env-json}/bin/bash-env-json"}
                chmod +x "$out/bin/plugin_nu_bash_env"
                runHook postBuild
              '';

              meta.mainProgram = "nu_plugin_bash_env";
            };
        };
      };
    };
}
