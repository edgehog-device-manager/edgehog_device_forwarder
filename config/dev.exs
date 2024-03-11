# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

import Config

config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "91eUYzx2/boApWkELv8qAEciRO0kEGh7mIj6i7O9biWh/dELQZlkWJVSA0kQm27X",
  watchers: []

config :edgehog_device_forwarder, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
