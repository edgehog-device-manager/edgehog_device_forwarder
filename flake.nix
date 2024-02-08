# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

{
  description = "Server component for remote shell on edgehog devices";
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = github:numtide/flake-utils;
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
    edgehog = {
      url = "github:noaccOS/edgehog/nix?dir=backend";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    elixir-utils.url = "github:noaccOS/elixir-utils";
  };
  outputs = { self, nixpkgs, edgehog, elixir-utils, flake-utils, ... }:
    {
      overlays.tools = elixir-utils.lib.asdfOverlay { src = ./.; wxSupport = false; };
      formatter = edgehog.formatter;
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.tools ]; };
      in {
        devShells.default = pkgs.elixirDevShell;
        packages = {
          update_copyright = pkgs.callPackage ./tools/update_copyright/default.nix { };
        };
      });
}
