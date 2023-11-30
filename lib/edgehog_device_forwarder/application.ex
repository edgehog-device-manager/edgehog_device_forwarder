# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EdgehogDeviceForwarderWeb.Telemetry,
      {Phoenix.PubSub, name: EdgehogDeviceForwarder.PubSub},
      EdgehogDeviceForwarder.TerminationCallbacks,
      EdgehogDeviceForwarderWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EdgehogDeviceForwarder.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    EdgehogDeviceForwarderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
