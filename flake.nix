{
  description = "Agda Language Server";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];
      imports = [
        ./nix/args.nix
        ./nix/packages.nix
        ./nix/shells.nix
      ];
    };
}
