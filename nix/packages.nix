{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      # Choose a GHC matching your stack resolver, e.g. ghc96 for lts-21
      ghc = pkgs.haskell.compiler.ghc96;

      # Nix-side non-Haskell deps needed by transitive Haskell packages (e.g., text-icu)
      systemDeps = [
        pkgs.zlib
        pkgs.gmp
        pkgs.pkg-config
        pkgs.icu
      ];

      # Build the Stack project in a Nix shell via the nixpkgs helper.
      # This mirrors the approach shown in Stack’s Nix docs and common recipes.
      alsDrv = pkgs.haskell.lib.buildStackProject {
        inherit ghc;
        name = "agda-language-server";
        src = self; # project root containing stack.yaml

        # Make non-Haskell deps visible to pkg-config/Cabal
        buildInputs = systemDeps;

        # Optional: if your stack build needs environment passthrough or impure shell toggles,
        # you can wrap stack via NIX_SHELL hooks; generally not needed if packages are complete.
      };
    in
    rec {
      packages.als = pkgs.stdenv.mkDerivation {
        pname = "agda-language-server";
        version = "unstable";

        # Reuse the Stack-built result; copy the built binary into $out
        # buildStackProject puts artifacts under .stack-work; use stack to copy-bins.
        src = self;

        nativeBuildInputs = [
          pkgs.stack
          ghc
        ] ++ systemDeps;

        # Optional runtime tools
        buildInputs = [
          pkgs.agda
        ];

        # Build by invoking stack inside the Nix-provided env, then install.
        # No manual TMPDIR gymnastics: let the Nix shell provide a sane env.
        buildPhase = ''
          runHook preBuild
          mkdir -p /build/home
          export HOME=/build/home
          export STACK_YAML=${self}/stack.yaml
          # Use system GHC provided by Nix, not Stack’s downloader.
          stack \
            --no-terminal \
            --system-ghc build \
            --copy-bins \
            --local-bin-path $TMPDIR/bin \
            --allow-different-user
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

      packages.default = packages.als;
    };
}
