{ pkgs, ... }: let
  builtins.readFile ./meta.json;
in pkgs.fetchgit {
  name = "quicklisp-cl-paypal-src";
  inherit name rev sha256;
};
