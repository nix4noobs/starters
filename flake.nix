{
  description = "nix starter flake pinned to 22.11";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11"; };

  outputs = { self, nixpkgs }:
    let
      allSystems = [
        "x86_64-linux" # AMD/Intel Linux
        "aarch64-linux" # ARM Linux
        "x86_64-darwin" # AMD/Intel macOS
        "aarch64-darwin" # ARM macOS
      ];

      forAllSystems = fn:
        nixpkgs.lib.genAttrs allSystems
        (system: fn { pkgs = import nixpkgs { inherit system; }; });

    in {
      # used when calling `nix fmt <path/to/flake.nix>`
      formatter = forAllSystems ({ pkgs }: pkgs.nixfmt);

      templates = {
        starter-22-11 = {
          path = ./templates/starter-22.11;
          description = "starter flake with formatter, utils and a dev shell";
        };
        basicvm-22-11 = {
          path = ./templates/basicvm-22.11;
          description = "starter for flake building a QEMU VM";
        };
      };
    };
}
