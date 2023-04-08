{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    { self
    , nixpkgs
    , utils
    , naersk
    , fenix
    , pre-commit-hooks
    ,
    }:
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          fenix.overlays.default
        ];
      };

      cf-tool = pkgs.stdenv.mkDerivation {
        pname = "cf";
        version = "1.0.0";
        src = pkgs.fetchzip {
          name = "cf";
          url = "https://github.com/xalanq/cf-tool/releases/download/v1.0.0/cf_v1.0.0_linux_64.zip";
          sha256 = "sha256-+losFMckuAq+H8dGs1+hqD124665TrX8LKkdWIucM0U=";
        };
        nativeBuildInptus = [ ];
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/bin
          cp -r cf $out/bin
        '';
        meta = with pkgs.lib; {
          homepage = "https://github.com/xalanq/cf-tool";
          description = "CodeForces CLI";
          sourceProvenance = with sourceTypes; [ binaryBytecode ];
          license = [ ];
          platforms = platforms.all;
          maintainers = [ ];
        };
      };

    in
    {

      checks = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            rustfmt.enable = true;
          };
          settings = {
            clippy = {
              denyWarnings = true;
            };
          };
        };
      };

      devShells.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = with pkgs; [
          (pkgs.fenix.complete.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ])
          cargo-watch
          pre-commit
          cf-tool
        ];

        RUST_LOG = "debug";
        nativeBuildInputs = [ pkgs.pkg-config ];
        RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
      };
    });
}
