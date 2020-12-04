{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-weblocks-stores-src";
  inherit name rev sha256;
};
