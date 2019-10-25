{ nixpkgs ? (import ./nixpkgs.nix), ... }:
let
  pkgs = import nixpkgs { config = {}; };
  parinfer-rust = pkgs.callPackage ./derivation.nix {};
  runVimTests = name: path: pkgs.stdenv.mkDerivation {
    name = "parinfer-rust-${name}-tests";
    src = ./tests/vim;
    buildPhase = ''
      printf 'Testing %s\n' '${path}'
      LC_ALL=en_US.UTF-8 \
        LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive \
        VIM_TO_TEST=${path} \
        PLUGIN_TO_TEST=${parinfer-rust}/share/vim-plugins/parinfer-rust \
        ${pkgs.vim}/bin/vim --clean -u run.vim
    '';
    installPhase = ''
      touch $out
    '';
  };

in {
  vim-tests = runVimTests "vim" "${pkgs.vim}/bin/vim";

  neovim-tests = runVimTests "neovim" "${pkgs.neovim}/bin/nvim";
}
