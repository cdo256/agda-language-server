{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    rec {
      packages.als = pkgs.stdenv.mkDerivation {
        pname = "agda-language-server";
        version = "unstable";

        src = ./.;

        nativeBuildInputs = [
          pkgs.stack
          pkgs.haskell.compiler.ghc96
          pkgs.zlib
          pkgs.gmp
          pkgs.cabal-install
          pkgs.which
          pkgs.pkg-config
          pkgs.icu
        ];

        buildInputs = [
          pkgs.agda
        ];

        buildPhase = ''
          runHook preBuild
          echo TMPDIR: $TMPDIR
          mkdir $TMPDIR/bin
          export STACK_YAML=${self + "/stack.yaml"}
          echo $STACK_YAML
          stack --no-terminal --system-ghc build --only-dependencies --test --bench --no-run-tests --no-run-benchmarks --local-bin-path $TMPDIR/bin
          stack --no-terminal --system-ghc build --copy-bins --local-bin-path $TMPDIR/bin
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/bin
          cp -v $TMPDIR/bin/als $out/bin/als
          runHook postInstall
        '';

        # Untested
        doCheck = false;

        meta = with pkgs.lib; {
          description = "Language Server for Agda";
          homepage = "https://github.com/agda/agda-language-server";
          license = licenses.mit;
          platforms = platforms.all;
        };
      };
      packages.default = packages.als;
    };
}
