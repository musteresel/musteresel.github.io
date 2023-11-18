with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "musteresel-blog";
  buildInputs = [pandoc];
}
