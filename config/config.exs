# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

import Config

config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: EdgehogDeviceForwarderWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EdgehogDeviceForwarder.PubSub,
  live_view: [signing_salt: "KhdMSuxy"],
  device_socket_timeout: :timer.minutes(1)

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

# HTTPRequests and WebSockets share the same ETS table
message_table = :message_table

config :edgehog_device_forwarder, EdgehogDeviceForwarder.Caches, [
  {EdgehogDeviceForwarder.Tokens, :token_table},
  {EdgehogDeviceForwarder.HTTPRequests, message_table},
  {EdgehogDeviceForwarder.WebSockets, message_table}
]

config :edgehog_device_forwarder, EdgehogDeviceForwarder.Forwarder,
  request_timeout: :timer.seconds(5)

import_config "#{config_env()}.exs"
