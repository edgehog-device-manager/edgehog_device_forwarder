# Copyright 2024 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.ErrorController do
  @moduledoc """
  Default fallback controller for common errors.
  """

  use EdgehogDeviceForwarderWeb, :controller

  def call(conn, {:error, :token_not_found}) do
    error = dgettext("errors", "Session not found or device not connected")

    conn
    |> send_resp(404, error)
    |> halt()
  end

  def call(conn, {:error, :request_timeout}) do
    error = dgettext("errors", "Request timeout")

    conn
    |> send_resp(408, error)
    |> halt()
  end

  def call(conn, {:error, :invalid_request_port}) do
    error = dgettext("errors", "The specified request port is not a valid port")

    conn
    |> send_resp(400, error)
    |> halt()
  end

  def call(conn, {:error, {:invalid_protocol, protocol}}) do
    error = dgettext("errors", "Request protocol not yet handled")
    error = ~s[#{error}: "#{protocol}"]

    conn
    |> send_resp(501, error)
    |> halt()
  end
end
