{
  pkgs,
  lib,
  stdenv,
  ...
}: let
  # Detect platform and OS
  platform =
    if stdenv.isDarwin
    then
      if stdenv.isAarch64
      then "arm64-apple-darwin-unsigned"
      else "x86_64-apple-darwin-unsigned"
    else if stdenv.isLinux
    then
      if stdenv.isx86_64
      then "x86_64-linux-gnu"
      else "aarch64-linux-gnu"
    else throw "Unsupported platform";

  # Platform-specific hashes
  hashes = {
    "x86_64-apple-darwin-unsigned" = "sha256-CaYWts/zywipxAAKqiFNNFFEHyR1uZ+2dgrFHhE8BTE=";
    "arm64-apple-darwin-unsigned" = "sha256-fq38pBiLmq14+tqlYBlIT/L1Zo+HyhGYMu1wh9KiDkc=";
    "x86_64-linux-gnu" = "sha256-REnq1YT+3AjUAoeyg/BjLqm3ap82U5HxCrrkd4LTFFA=";
    "aarch64-linux-gnu" = "sha256-M8RDnoYS11cpSEDOEya2byIHYw8nZLpJr8Z/ap8rHxU=";
  };

  # Construct the appropriate binary URL
  binaryUrl = "https://github.com/Sjors/bitcoin/releases/download/sv2-tp-0.1.17/bitcoin-sv2-tp-0.1.17-${platform}.tar.gz";

  # Fetch the pre-built binary
  binary = pkgs.fetchurl {
    url = binaryUrl;
    hash = hashes.${platform};
  };
in
  pkgs.stdenv.mkDerivation {
    name = "bitcoind-sv2";
    version = "0.1.17";
    src = binary;

    nativeBuildInputs =
      [pkgs.gnutar pkgs.gzip]
      ++ lib.optionals stdenv.isLinux [
        pkgs.autoPatchelfHook
        pkgs.gcc.cc.lib
      ];

    sourceRoot = "bitcoin-sv2-tp-0.1.17";

    dontBuild = true;
    dontConfigure = true;

    installPhase =
      ''
        mkdir -p $out/bin
        cp bin/bitcoind bin/bitcoin-cli $out/bin/
        cp -r share $out/
      ''
      + lib.optionalString stdenv.isDarwin ''
        # Code sign the binaries on macOS
        /usr/bin/codesign -s - $out/bin/bitcoind
        /usr/bin/codesign -s - $out/bin/bitcoin-cli
      '';

    installCheckPhase = ''
      $out/bin/bitcoin-cli --version
    '';

    meta = {
      description = "Bitcoin SV2 Template Provider";
      homepage = "https://github.com/Sjors/bitcoin";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin ++ lib.platforms.linux;
    };
  }
