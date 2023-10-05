# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :edgehog_device_forwarder

  @session_options [
    store: :cookie,
    key: "_edgehog_device_forwarder_key",
    signing_salt: "6qulWaO7",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :edgehog_device_forwarder,
    gzip: false,
    only: EdgehogDeviceForwarderWeb.static_paths()

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug EdgehogDeviceForwarderWeb.Router
end
