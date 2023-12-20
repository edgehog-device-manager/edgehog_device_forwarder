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
      url = "github:edgehog-device-manager/edgehog?dir=backend";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
    edgehog-base = {
      url = "github:edgehog-device-manager/edgehog";
      flake = false;
    };
    elixir-utils.url = "github:noaccOS/elixir-utils";
  };
  outputs = { self, nixpkgs, edgehog, flake-utils, elixir-utils, edgehog-base, ... }:
    {
      # TODO: reset to previous value without edgehog-base once upstream updates elixir-utils dependency
      # overlays.tools = edgehog.overlays.tools;
      overlays.tools = elixir-utils.lib.asdfOverlay { src = edgehog-base; };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.tools ]; };
        mkPackage = mixEnv: pkgs.customMixRelease { src = ./.; depsHashFile = ./.nix/hash; inherit mixEnv; };
      in
      {
        formatter = edgehog.formatter.${system};
        devShells.default = pkgs.elixirDevShell;
        packages.default = mkPackage "prod";
        packages.dev = mkPackage "dev";
      });
}
