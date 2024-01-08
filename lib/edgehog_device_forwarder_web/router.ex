# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.Router do
  use EdgehogDeviceForwarderWeb, :router

  scope "/v1/:session/:protocol/:port", EdgehogDeviceForwarderWeb do
    match :*, "/*path", UserController, :handle_in
  end

  if Application.compile_env(:edgehog_device_forwarder, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: EdgehogDeviceForwarderWeb.Telemetry
    end
  end
end
