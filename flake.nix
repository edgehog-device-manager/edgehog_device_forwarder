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
  };
  outputs = { self, nixpkgs, edgehog, flake-utils, ... }:
    {
      overlays.tools = edgehog.overlays.tools;
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.tools ]; };
      in {
        formatter = edgehog.formatter.${system};
        devShells.default = pkgs.elixirDevShell;
      });
}
