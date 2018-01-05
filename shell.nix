with import <nixpkgs> {};

let
  project-relative-links = import ./utils/pandoc-project-relative-links/default.nix {};
in
stdenv.mkDerivation {
  name = "musteresel-blog";
  buildInputs = [pandoc project-relative-links];
}
