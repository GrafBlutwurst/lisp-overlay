{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-asdf-dependency-grovel-src";
  inherit name rev sha256;
};
