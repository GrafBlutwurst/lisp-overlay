{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-trivial-battery-src";
  inherit name rev sha256;
};
