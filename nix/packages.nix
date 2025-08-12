{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = rec {
        ghc = pkgs.haskell.compiler.ghc910;
        als-stack = pkgs.haskell.lib.buildStackProject {
          name = "agda-language-server";
          src = self; # project root containing stack.yaml
          inherit ghc;

          # Make non-Haskell deps visible to pkg-config/Cabal
          buildInputs = [
            pkgs.zlib
            pkgs.gmp
            pkgs.pkg-config
            pkgs.icu
          ];

          # Optional: if your stack build needs environment passthrough or impure shell toggles,
          # you can wrap stack via NIX_SHELL hooks; generally not needed if packages are complete.
        };
        agdaSrc = pkgs.fetchFromGitHub {
          owner = "agda";
          repo = "agda";
          rev = "v2.7.0.1"; # exact commit/tag your submodule pins
          sha256 = "sha256-N03x5v6ob9ZTuQFknULpEveozQbtDg6wiwNWI81bEZ8=";
          fetchSubmodules = true;
        };
        # ghc = ;
        als = pkgs.stdenv.mkDerivation {
          pname = "agda-language-server";
          version = "unstable";

          # Reuse the Stack-built result; copy the built binary into $out
          # buildStackProject puts artifacts under .stack-work; use stack to copy-bins.
          src = self;

          nativeBuildInputs = [
            pkgs.stack
            ghc
            pkgs.agda
            pkgs.zlib
            pkgs.gmp
            pkgs.pkg-config
            pkgs.icu
            pkgs.which
          ];

          buildInputs = [
            pkgs.agda
          ];

          # Build by invoking stack inside the Nix-provided env, then install.
          # No manual TMPDIR gymnastics: let the Nix shell provide a sane env.
          buildPhase = ''
            runHook preBuild
            mkdir -p /build/home
            ghc --version
            export HOME=/build/home
            mkdir -p /build/stack
            export STACK_ROOT=/build/stack
            export STACK_YAML=/build/source/stack.yaml
            ln -s ${agdaSrc} /build/source/vendor/Agda-2.7.0.1
            stack \
              --no-nix \
              --no-terminal \
              --system-ghc build \
              --no-install-ghc \
              --copy-bins \
              --local-bin-path $TMPDIR/bin \
              --allow-different-user
            echo DONE##
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin
            cp -v $TMPDIR/bin/als $out/bin/als
            runHook postInstall
          '';

          # Tests can be enabled if the project has them; otherwise leave false.
          doCheck = false;

          meta = with lib; {
            description = "Language Server for Agda (built with Stack in a Nix environment)";
            homepage = "https://github.com/agda/agda-language-server";
            license = licenses.mit;
            platforms = platforms.all;
          };
        };

        default = als;

      };
    };
}
