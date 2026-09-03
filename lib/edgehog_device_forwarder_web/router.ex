# Copyright 2023-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.Router do
  use EdgehogDeviceForwarderWeb, :router

  if Application.compile_env(:edgehog_device_forwarder, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: EdgehogDeviceForwarderWeb.Telemetry
    end
  end

  get "/health", EdgehogDeviceForwarderWeb.HealthController, :status
end
