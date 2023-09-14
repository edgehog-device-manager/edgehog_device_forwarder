# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

import Config

config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: EdgehogDeviceForwarderWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EdgehogDeviceForwarder.PubSub,
  live_view: [signing_salt: "KhdMSuxy"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
