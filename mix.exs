# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.MixProject do
  use Mix.Project

  def project do
    [
      app: :edgehog_device_forwarder,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {EdgehogDeviceForwarder.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7.7"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:con_cache, "~> 1.0"},
      {:typed_struct, "~> 0.1.4"},
      {:elixir_uuid, "~> 1.2"},
      {
        :edgehog_device_forwarder_proto,
        git: "https://github.com/noaccOS/edgehog-device-forwarder-proto",
        branch: "feat/elixir-gen",
        sparse: "elixir/edgehog_device_forwarder_proto"
      }
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
