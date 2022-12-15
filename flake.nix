{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: let
    overlays = {
      default = import ./overlay.nix;
    };
  in {
    inherit overlays;
  } // (inputs.flake-utils.lib.eachDefaultSystem(system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ inputs.self.overlays.default ];
    };
  in {
    packages = {
      inherit (pkgs) parinfer-rust;
      default = inputs.self.packages.${system}.parinfer-rust;
    };

    devShells.default = pkgs.mkShell {
      inputsFrom = [ inputs.self.packages.${system}.default ];
    };

    checks = let
      parinfer-rust = pkgs.parinfer-rust;
      localeEnv = if pkgs.stdenv.isDarwin then "" else "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive";

      runVimTests = name: path: pkgs.stdenv.mkDerivation {
        name = "parinfer-rust-${name}-tests";
        src = ./tests/vim;
        buildPhase = ''
          printf 'Testing %s\n' '${path}'
          LC_ALL=en_US.UTF-8 \
            ${localeEnv} \
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

      kakoune-tests = pkgs.stdenv.mkDerivation {
        name = "parinfer-rust-kakoune-tests";
        src = ./tests/kakoune;
        buildInputs = [
          pkgs.kakoune-unwrapped
          parinfer-rust
        ];
        buildPhase = ''
          patchShebangs ./run.sh
          PLUGIN_TO_TEST=${parinfer-rust}/share/kak/autoload/plugins ./run.sh
        '';
        installPhase = ''
          touch $out
        '';
      };
    };
  }));
}
