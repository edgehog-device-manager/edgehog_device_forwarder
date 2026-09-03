# Copyright 2023-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.ForwarderEndpoint do
  use Phoenix.Endpoint, otp_app: :edgehog_device_forwarder

  @timeout_path [__MODULE__, :device_socket_timeout]
  @timeout Application.compile_env!(:edgehog_device_forwarder, @timeout_path)

  socket "/device", EdgehogDeviceForwarderWeb.DeviceSocket,
    websocket: [
      timeout: @timeout,
      error_handler: {EdgehogDeviceForwarderWeb.DeviceSocket, :connection_error, []}
    ],
    longpoll: false

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :forwarder_endpoint]

  plug EdgehogDeviceForwarderWeb.BodyParser

  plug EdgehogDeviceForwarderWeb.ForwarderRouter
end
