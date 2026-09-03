# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

import Config

if System.get_env("PHX_SERVER") do
  config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Endpoint, server: true
  config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.ForwarderEndpoint, server: true
end

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  service_host = System.get_env("PHX_HOST_SERVICE") || "service.#{host}"

  port = String.to_integer(System.get_env("PORT") || "4000")
  service_port = String.to_integer(System.get_env("SERVICE_PORT") || "4001")

  config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Guardian,
    issuer: "edgehog_device_forwarder",
    secret_key: {System, :get_env, ["SECRET_KEY_BASE"]}

  config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.Endpoint,
    url: [host: service_host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: service_port
    ],
    secret_key_base: secret_key_base

  config :edgehog_device_forwarder, EdgehogDeviceForwarderWeb.ForwarderEndpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base
end
