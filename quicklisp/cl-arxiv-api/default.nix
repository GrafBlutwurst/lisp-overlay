{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-cl-arxiv-api-src";
  inherit name rev sha256;
};
