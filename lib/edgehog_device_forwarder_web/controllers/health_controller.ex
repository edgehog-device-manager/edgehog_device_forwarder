# Copyright 2023-2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.HealthController do
  use EdgehogDeviceForwarderWeb, :controller

  def status(conn, _params) do
    case EdgehogDeviceForwarder.Health.status() do
      :good ->
        conn
        |> send_resp(:ok, "")
        |> halt()

      :bad ->
        conn
        |> send_resp(:service_unavailable, "")
        |> halt()
    end
  end
end
