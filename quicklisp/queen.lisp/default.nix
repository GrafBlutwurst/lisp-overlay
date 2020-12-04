{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-queen.lisp-src";
  inherit name rev sha256;
};
