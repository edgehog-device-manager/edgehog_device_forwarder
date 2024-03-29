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
      deps: deps(),
      dialyzer: dialyzer_opts(Mix.env())
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

  defp dialyzer_opts(:test) do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:ex_unit]
    ]
  end

  defp dialyzer_opts(_env), do: []

  defp deps do
    [
      {:con_cache, "~> 1.0"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {
        :edgehog_device_forwarder_proto,
        git: "https://github.com/edgehog-device-manager/edgehog-device-forwarder-proto",
        sparse: "elixir/edgehog_device_forwarder_proto"
      },
      {:elixir_uuid, "~> 1.2"},
      {:gettext, "~> 0.23"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:plug_cowboy, "~> 2.6"},
      {:qex, "~> 0.5.1"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:typedstruct, "~> 0.5"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
