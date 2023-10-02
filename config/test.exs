# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

import Config

config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "lmBXbq8UBD2GQThDB8JDjhWjp85D16gaePjO6l5fS+DULN3oLbdZpKtgdRgfBLdn",
  server: false

config :edgehog_device_forwarder, EdgehogDeviceForwarder.Forwarder, request_timeout: 100

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
