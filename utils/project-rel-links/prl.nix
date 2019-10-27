{stdenv, python}:

stdenv.mkDerivation {
  name = "prl";
  version = "0.1.0";
  src = [./prl.py];
  unpackPhase = ''
    for srcFile in $src; do
      cp $srcFile $(stripHash $srcFile)
    done
  '';
  buildInputs = [(python.withPackages (ps: [ps.pandocfilters]))];
  dontBuild = true;
  installPhase =
    ''
      mkdir $out
      mkdir $out/bin
      mv prl.py $out/bin/
      ln -s $out/bin/prl.py $out/bin/pandoc-project-relative-links
    '';
}
