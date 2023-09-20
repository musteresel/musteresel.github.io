with import <nixpkgs> {};

let
  prl = callPackage (import ./utils/project-rel-links/prl.nix)
{
  python = python3;
};
in
stdenv.mkDerivation {
  name = "musteresel-blog";
  buildInputs = [pandoc prl];
}
