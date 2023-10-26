# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.WebSockets do
  require Logger

  @table EdgehogDeviceForwarder.Cache.for(__MODULE__)

  @type controller :: pid()
  @type id :: binary()
  @type socket :: EdgehogDeviceForwarder.Tokens.TokenData.socket()


  @spec upgrade(id, socket) ::
          :ok | {:error, :http_request_not_found}
  def upgrade(request_id, socket) do
    ConCache.isolated(@table, request_id, fn ->
      case ConCache.get(@table, request_id) do
        {:upgrading, :websocket} ->
          ConCache.dirty_put(@table, request_id, {:websocket, socket})

        nil ->
          "upgrade: request_id #{inspect(request_id)} not found"
          |> Logger.info(tag: "invalid_http_id")

          {:error, :http_request_not_found}

        other ->
          "upgrade: request_id #{inspect(request_id)}. expected {:upgrading, :websocket}, got #{inspect(other)}"
          |> Logger.info(tag: "invalid_http_id")

          {:error, :http_request_not_found}
      end
    end)
  end

  @spec fetch(id) ::
          {:ok, socket} | {:error, :websocket_not_found}
  def fetch(socket_id) do
    case ConCache.get(@table, socket_id) do
      {:websocket, socket} ->
        {:ok, socket}

      nil ->
        "fetch: socket_id #{inspect(socket_id)} not found"
        |> Logger.info(tag: "invalid_websocket_id")

        {:error, :websocket_not_found}

      x ->
        "fetch: socket_id #{inspect(socket_id)}: expected :websocket, found #{inspect(x)}"
        |> Logger.info(tag: "invalid_websocket_id")

        {:error, :websocket_not_found}
    end
  end

  @spec close(id) :: :ok | {:error, :websocket_not_found}
  def close(socket_id) do
    ConCache.isolated(@table, socket_id, fn ->
      case ConCache.get(@table, socket_id) do
        {:websocket, _} ->
          ConCache.dirty_delete(@table, socket_id)

        nil ->
          "close: socket_id: #{inspect(socket_id)}: not found"
          |> Logger.info(tag: "invalid_socket_id")

          {:error, :websocket_not_found}

        other ->
          "close: socket_id: #{inspect(socket_id)}: expected :websocket, found #{inspect(other)}"
          |> Logger.info(tag: "invalid_socket_id")

          {:error, :websocket_not_found}
      end
    end)
  end
end
