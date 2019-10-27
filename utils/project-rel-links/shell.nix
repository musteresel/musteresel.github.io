{pkgs ? import <nixpkgs> {}}:
with pkgs;

callPackage (import ./prl.nix) { python = python37;}
