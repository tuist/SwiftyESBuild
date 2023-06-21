{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;
  elixir = beam.packages.erlangR25.elixir_1_14;
in
pkgs.mkShell {
  buildInputs = [
    pkgs.go
  ]
  ++ optional stdenv.isLinux libnotify # For ExUnit Notifier on Linux.
  ++ optional stdenv.isLinux inotify-tools # For file_system on Linux.
  ++ optional stdenv.isDarwin terminal-notifier # For ExUnit Notifier on macOS.
  ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    # For file_system on macOS.
    CoreFoundation
    CoreServices
  ]);
}