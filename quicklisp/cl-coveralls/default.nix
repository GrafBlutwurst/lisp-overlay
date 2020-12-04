{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-cl-coveralls-src";
  inherit name rev sha256;
};
