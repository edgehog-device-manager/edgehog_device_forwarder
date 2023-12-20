# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.WebSockets do
  @moduledoc """
  Interface to the cache for the WebSockets connections.
  """

  require Logger
  alias EdgehogDeviceForwarder.HTTPRequests
  alias EdgehogDeviceForwarder.WebSockets.Data
  alias EdgehogDeviceForwarder.WebSockets.Core
  alias EdgehogDeviceForwarder.WebSockets.Errors
  alias EdgehogDeviceForwarder.TerminationCallbacks

  @cache_id EdgehogDeviceForwarder.Caches.cache_id_for(__MODULE__)

  @type id :: Data.socket_id()
  @type user_socket :: Core.user_socket()
  @type message :: Core.message()

  @doc """
  Finalize the upgrade of an HTTP connection to a WebSocket.
  """
  @spec upgrade(HTTPRequests.id(), user_socket, Data.t()) ::
          :ok | {:error, :http_request_not_found}
  def upgrade(request_id, socket, socket_data) do
    ConCache.update(@cache_id, request_id, fn
      {:upgrading, :websocket, queue} ->
        monitor_user_socket(socket, socket_data)
        {:ok, Core.upgrade(request_id, socket, queue)}

      other ->
        Errors.upgrade_invalid_request_id(request_id, other)
    end)
  end

  @doc """
  Forward the message to the target WebSocket.
  """
  @spec forward(id, message) ::
          :ok | {:error, :websocket_is_closing} | {:error, :websocket_not_found}
  def forward(socket_id, message) do
    ConCache.isolated(@cache_id, socket_id, fn ->
      case ConCache.get(@cache_id, socket_id) do
        {:websocket, socket} ->
          Core.forward(socket_id, socket, message)

        {:upgrading, :websocket, queue} ->
          Core.enqueue_message(socket_id, queue, message)

        {:closing, :websocket, :user} ->
          case message do
            {:close, _} -> Core.socket_closing_handshake_complete(socket_id)
            _ -> Errors.received_message_in_closing_websocket(socket_id, message)
          end

        other ->
          Errors.forward_to_invalid_socket_id(socket_id, message, other)
      end
    end)
  end

  @doc """
  Begin the WebSocket closing handshake.

  This function always starts the handshake from the user side and should not be called when
  the device is starting the handshake.
  """
  @spec close(id, user_socket) :: :ok | {:error, :websocket_not_found}
  def close(socket_id, device_socket) do
    ConCache.isolated(@cache_id, socket_id, fn ->
      case ConCache.get(@cache_id, socket_id) do
        {:websocket, _} ->
          Core.user_start_socket_closing_handshake(socket_id, device_socket)

        {:closing, :websocket, :device} ->
          Core.socket_closing_handshake_complete(socket_id)

        other ->
          Errors.close_invalid_socket_id(socket_id, other)
      end
    end)
  end

  @spec monitor_user_socket(user_socket, Data.t()) :: :ok
  defp monitor_user_socket(socket, socket_data) do
    %Data{socket_id: socket_id, device: device_socket} = socket_data

    TerminationCallbacks.add(socket, fn -> close(socket_id, device_socket) end)
  end
end
