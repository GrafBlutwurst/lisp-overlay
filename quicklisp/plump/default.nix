{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-plump-src";
  inherit name rev sha256;
};
