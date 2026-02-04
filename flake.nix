{
  description = "StackOne Skills - Claude Code skills collection";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      git-hooks,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
            };
            settings.formatter.oxfmt = {
              command = "${pkgs.oxfmt}/bin/oxfmt";
              options = [ "--no-error-on-unmatched-pattern" ];
              includes = [ "*" ];
            };
          };

          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              gitleaks = {
                enable = true;
                name = "gitleaks";
                entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged";
                language = "system";
                pass_filenames = false;
              };
              treefmt = {
                enable = true;
                package = treefmtEval.config.build.wrapper;
              };
            };
          };
        in
        {
          formatter = treefmtEval.config.build.wrapper;

          devShells.default = pkgs.mkShellNoCC {
            shellHook = pre-commit-check.shellHook;
          };
        };
    };
}
