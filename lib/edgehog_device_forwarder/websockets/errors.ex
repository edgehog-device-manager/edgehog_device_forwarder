# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.WebSockets.Errors do
  @moduledoc """
  Error handling for `EdgehogDeviceForwarder.WebSockets`
  """

  require Logger

  alias EdgehogDeviceForwarder.HTTPRequests
  alias EdgehogDeviceForwarder.WebSockets.Core
  alias EdgehogDeviceForwarder.WebSockets.Data

  @spec upgrade_invalid_request_id(HTTPRequests.id(), term) :: {:error, :http_request_not_found}
  def upgrade_invalid_request_id(request_id, nil = _value_found) do
    "upgrade: request_id #{inspect(request_id)}: not found"
    |> Logger.notice(tag: "invalid_http_id")

    {:error, :http_request_not_found}
  end

  def upgrade_invalid_request_id(request_id, value_found) do
    """
    upgrade: request_id #{inspect(request_id)}: \
    expected {:upgrading, :websocket}, got #{inspect(value_found)}
    """
    |> Logger.notice(tag: "invalid_http_id")

    {:error, :http_request_not_found}
  end

  @spec forward_to_invalid_socket_id(Data.socket_id(), Core.message(), term) ::
          {:error, :websocket_not_found}
  def forward_to_invalid_socket_id(socket_id, message, nil = _value_found) do
    """
    ws: forward: socket_id #{inspect(socket_id)} not found.
    message received: #{inspect(message, pretty: true)}"
    """
    |> Logger.notice(tag: "invalid_websocket_id")

    {:error, :websocket_not_found}
  end

  def forward_to_invalid_socket_id(socket_id, message, value_found) do
    """
    ws: forward: socket_id #{inspect(socket_id)}: expected :websocket, found #{inspect(value_found)}
    message received: #{inspect(message, pretty: true)}
    """
    |> Logger.notice(tag: "invalid_websocket_id")

    {:error, :websocket_not_found}
  end

  @spec close_invalid_socket_id(Data.socket_id(), term) :: {:error, :websocket_not_found}
  def close_invalid_socket_id(socket_id, nil = _value_found) do
    "close: socket_id #{inspect(socket_id)}: not found"
    |> Logger.notice(tag: "invalid_websocket_id")

    {:error, :websocket_not_found}
  end

  def close_invalid_socket_id(socket_id, value_found) do
    "close: socket_id #{inspect(socket_id)}: expected :websocket, found #{inspect(value_found)}"
    |> Logger.notice(tag: "invalid_websocket_id")

    {:error, :websocket_not_found}
  end

  @spec received_message_in_closing_websocket(Data.socket_id(), Core.message()) ::
          {:error, :websocket_is_closing}
  def received_message_in_closing_websocket(socket_id, message) do
    """
    ws: forward: socket_id #{inspect(socket_id)}:
    websocket is closing, received: #{inspect(message, pretty: true)}
    """
    |> Logger.notice(tag: "invalid_websocket_id")

    {:error, :websocket_is_closing}
  end
end
