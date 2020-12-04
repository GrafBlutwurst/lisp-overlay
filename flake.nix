{
  description = "Extremely zealous lisp overlay";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = inputs@{ self, nixpkgs }: let 
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
  in {

    repos = {
      quicklisp = rec {
        # Repository dist pin
        meta = builtins.fromJSON (builtins.readFile ./quicklisp/meta.json);

        # Quicklisp dist fetch
        dist = forAllSystems (system: let
          pkgs = nixpkgs.legacyPackages.${system};
        in pkgs.fetchgit {
          inherit (self.repos.quicklisp.meta) url rev sha256;
        });

        # Package specs
        specs = forAllSystems (system: builtins.mapAttrs
          (name: _: let
            value = nixpkgs.lib.removeSuffix "\n" (
              builtins.readFile "${dist.${system}}/projects/${name}/source.txt"
            );
            kvPair = nixpkgs.lib.splitString " " value;
          in {
            type = nixpkgs.lib.elemAt kvPair 0;
            url = nixpkgs.lib.elemAt kvPair 1;
            data = if builtins.length kvPair > 2
                   then nixpkgs.lib.elemAt kvPair 2
                   else null;
            inherit value;
          })
          (builtins.readDir "${dist.${system}}/projects"));

        # Package updater script snippets
        updaters = forAllSystems (system: let
          pkgs = nixpkgs.legacyPackages.${system};
        in builtins.mapAttrs
          (name: { type, url, ... }: let
            inherit (self.lib.quicklisp) handler;
          in if builtins.hasAttr type handler then handler.${type} { inherit name url pkgs; }
             else builtins.trace "Quicklisp - Unhandled type: ${type} (for ${name})" null)
          (specs.${system})
        );

        # Enumeration of valid "type" values, just to eval
        types = forAllSystems (system: nixpkgs.lib.unique (
          nixpkgs.lib.mapAttrsToList (k: v: v.type) specs.${system}
        ));
      };
    };

    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.dists.quicklisp);

    apps = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (nixpkgs.lib) concatStringsSep mapAttrsToList;
    in {
      quicklisp-update-dist = rec {
        type = "app";
        url = "git://github.com/quicklisp/quicklisp-projects";
        program = (pkgs.writeShellScript "update-quicklisp-dist" ''set -ex
          test -e flake.nix || (echo "Must be run from repo root"; exit 1)
          mkdir -p quicklisp
          ${pkgs.nix-prefetch-git}/bin/nix-prefetch-git --url '${url}' > quicklisp/meta.json
        '').outPath;
      };
      quicklisp-update-pkgs = rec {
        type = "app";
        updaters = self.repos.quicklisp.updaters.${system};
        program = (pkgs.writeShellScript "update-quicklisp-pkgs" ''set -ex
          test -e flake.nix || (echo "Must be run from repo root"; exit 1)
          mkdir -p quicklisp && cd quicklisp
          ${concatStringsSep "" (mapAttrsToList (name: updater: ''
            echo -- ${name}
            ${if updater != null then updater else "echo Unavailable"}
          '') updaters)}
        '').outPath;
      };
      quicklisp-add-pkgs = rec {
        type = "app";
        updaters = self.repos.quicklisp.updaters.${system};
        program = (pkgs.writeShellScript "update-quicklisp-pkgs" ''set -ex
          test -e flake.nix || (echo "Must be run from repo root"; exit 1)
          mkdir -p quicklisp && cd quicklisp
          ${concatStringsSep "" (mapAttrsToList (name: updater: ''
            echo -- ${name}
            if test ! -e ${name}; then
              ${if updater != null then updater else "echo Unavailable"}
            fi
          '') updaters)}
        '').outPath;
      };
    });

    lib = {
      quicklisp = rec {
        handler.git = { name, url, pkgs, ... }: let
          buildScript = pkgs.writeText "quicklisp-${name}-fetch" ''
            { pkgs, ... }: let
              meta = builtins.readFile ./meta.json;
            in pkgs.fetchgit {
              name = "quicklisp-${name}-src";
              inherit (meta) rev sha256;
            };
          '';
        in pkgs.writeShellScript "quicklisp-${name}" ''
          mkdir -p ${name}
          ${pkgs.nix-prefetch-git}/bin/nix-prefetch-git --url '${url}' > ${name}/meta.json
          cp ${buildScript} ${name}/default.nix
        '';
        handler.mercurial = { name, url, pkgs, ... }: let
          buildScript = pkgs.writeText "quicklisp-${name}-fetch" ''
            { pkgs, ... }: let
              sha256 = builtins.readFile ./meta.hash;
            in builtins.fetchMercurial {
              inherit sha256;
            };
          '';
        in pkgs.writeShellScript "quicklisp-${name}" ''
          mkdir -p ${name}
          ${pkgs.nix-prefetch-hg}/bin/nix-prefetch-hg --url '${url}' > ${name}/meta.hash
          cp ${buildScript} ${name}/default.nix
        '';
        handler.https = { name, url, pkgs, ... }: let
          buildScript = pkgs.writeText "quicklisp-${name}-fetch" ''
            { pkgs, ... }: let
              sha256 = builtins.readFile ./meta.hash;
            in builtins.fetchTarball {
              inherit sha256;
            };
          '';
        in pkgs.writeShellScript "quicklisp-${name}" ''
          mkdir -p ${name}
          ${pkgs.nix}/bin/nix-prefetch-url --unpack '${url}' > ${name}/meta.hash
          cp ${buildScript} ${name}/default.nix
        '';
        handler.http = handler.https;
        handler.latest-github-tag = handler.git; # Maybe should handle this better
        handler.latest-github-release = handler.git; # Maybe should handle this better
        handler.tagged-git = handler.git; # Maybe should handle this better
      };
    };

  };
}
