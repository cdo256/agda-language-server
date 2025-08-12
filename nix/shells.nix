{
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          pkgs.haskell.compiler.ghc910
          pkgs.stack
          pkgs.agda
          pkgs.git
          pkgs.zlib
          pkgs.gmp
          pkgs.pkg-config
          pkgs.icu
        ];
        shellHook = ''
          echo "Agda Language Server shell"
          echo " - stack repl  # then :main -p to run ALS on localhost:4096"
          echo " - stack build --copy-bins --local-bin-path ./dist/bin"
        '';
      };
    };
}
