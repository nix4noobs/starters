{
  description = "build qemu image of NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixos-generators = { url = "github:nix-community/nixos-generators"; };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      allSystems = [
        "x86_64-linux" # AMD/Intel Linux
        "x86_64-darwin" # AMD/Intel macOS
        "aarch64-linux" # ARM Linux
        "aarch64-darwin" # ARM macOS
      ];

      forAllSystems = fn:
        nixpkgs.lib.genAttrs allSystems
        (system: fn { pkgs = import nixpkgs { inherit system; }; });

    in {
      # used when calling `nix fmt <path/to/flake.nix>`
      formatter = forAllSystems ({ pkgs, ... }: pkgs.nixfmt);

      # $ nix build <flake-ref>#vm
      # --
      # This builds the virtual machine
      packages = forAllSystems ({ pkgs, ... }: {
        vm = nixos-generators.nixosGenerate {
          system = pkgs.system;
          modules = [
            # add configuration.nix here
            (import ./configuration.nix { inputs = self.inputs; })
          ];
          format = "qcow";
        };
      });

      # $ nix run <flake-ref>#<app-name>
      # -- 
      # These `apps` entries wraps the shell scripts `make-overlay`
      # and `runvm` in the scripts directory, providing the shell and all
      # other programs the script relies on.
      apps = forAllSystems ({ pkgs, ... }:
        let
          # package shell script for execution in nix env using nix deps
          make-overlay-script = pkgs.runCommandLocal "make-overlay" {
            script = ./scripts/make-overlay;
            nativeBuildInputs = [ pkgs.makeWrapper ];
          } ''
            makeWrapper $BASH $out/bin/make-overlay.sh \
              --add-flags $script \
              --prefix PATH : ${
                pkgs.lib.makeBinPath (with pkgs; [ bash qemu coreutils ])
              }
          '';
          runvm-script = pkgs.runCommandLocal "runvm" {
            script = ./scripts/runvm;
            nativeBuildInputs = [ pkgs.makeWrapper ];
          } ''
            makeWrapper $bash $out/bin/runvm.sh \
              --add-flags $script \
              --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ bash qemu ])}
          '';
        in {
          runvm = {
            type = "app";
            program = "${runvm-script}/bin/runvm.sh";
          };
          make-overlay = {
            type = "app";
            program = "${make-overlay-script}/bin/make-overlay.sh";
          };
        });
    };
}
