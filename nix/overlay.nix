pkgs: _:
let
  mkPoetryEnv = { groups, python, extras ? [ "*" ] }: pkgs.poetry2nix.mkPoetryEnv {
    inherit python groups extras;
    projectDir = pkgs.gitignoreSource ../.;
    editablePackageSources = { ibis = pkgs.gitignoreSource ../ibis; };
    overrides = [
      (import ../poetry-overrides.nix)
      pkgs.poetry2nix.defaultPoetryOverrides
    ];
    preferWheels = true;
  };

  mkPoetryDevEnv = python: mkPoetryEnv {
    inherit python;
    groups = [ "dev" "docs" "test" ];
  };
in
{
  ibisTestingData = pkgs.fetchFromGitHub {
    owner = "ibis-project";
    repo = "testing-data";
    rev = "master";
    sha256 = "sha256-BZWi4kEumZemQeYoAtlUSw922p+R6opSWp/bmX0DjAo=";
  };

  rustNightly = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.minimal);

  prettier = pkgs.writeShellApplication {
    name = "prettier";
    runtimeInputs = [ ];
    text = ''
      ${pkgs.nodePackages.prettier}/bin/prettier \
      --plugin-search-dir "${pkgs.nodePackages.prettier-plugin-toml}/lib" "$@"
    '';
  };

  ibis38 = pkgs.python38Packages.callPackage ./ibis.nix { };
  ibis39 = pkgs.python39Packages.callPackage ./ibis.nix { };
  ibis310 = pkgs.python310Packages.callPackage ./ibis.nix { };

  ibisDevEnv38 = mkPoetryDevEnv pkgs.python38;
  ibisDevEnv39 = mkPoetryDevEnv pkgs.python39;
  ibisDevEnv310 = mkPoetryDevEnv pkgs.python310;

  ibisSmallDevEnv = mkPoetryEnv {
    python = pkgs.python310;
    groups = [ "dev" ];
    extras = [ ];
  };

  changelog = pkgs.writeShellApplication {
    name = "changelog";
    runtimeInputs = [ pkgs.nodePackages.conventional-changelog-cli ];
    text = "conventional-changelog --config ./.conventionalcommits.js";
  };

  update-lock-files = pkgs.writeShellApplication {
    name = "update-lock-files";
    runtimeInputs = [ pkgs.poetry ];
    text = ''
      poetry lock --no-update
      poetry export --with dev --with test --with docs --without-hashes --no-ansi > requirements.txt
    '';
  };
}