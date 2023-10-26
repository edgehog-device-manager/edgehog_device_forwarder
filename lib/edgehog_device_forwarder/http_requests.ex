# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.HTTPRequests do
  require Logger

  @table EdgehogDeviceForwarder.Cache.for(__MODULE__)

  @type id :: binary()
  @type fetch_action :: :respond | {:upgrade, :websocket}
  @type controller :: pid()
  @type socket :: EdgehogDeviceForwarder.Tokens.TokenData.socket()

  @spec new(controller) :: id
  def new(controller) do
    request_id = UUID.uuid4(:raw)

    case ConCache.insert_new(@table, request_id, {:http, controller}) do
      :ok -> request_id
      {:error, :already_exists} -> new(controller)
    end
  end

  @spec fetch(id, fetch_action) ::
          {:ok, controller} | {:error, :http_request_not_found}
  def fetch(request_id, action) do
    ConCache.isolated(@table, request_id, fn ->
      case ConCache.get(@table, request_id) do
        {:http, controller} ->
          # we already have the lock from the isolated/3 call
          case action do
            :respond ->
              ConCache.dirty_delete(@table, request_id)

            {:upgrade, :websocket} ->
              ConCache.dirty_put(@table, request_id, {:upgrading, :websocket})
          end

          {:ok, controller}

        nil ->
          "fetch: request_id #{inspect(request_id)} not found"
          |> Logger.info(tag: "invalid_http_id")

          {:error, :http_request_not_found}

        other ->
          "fetch: request_id #{inspect(request_id)}. expected :http, got #{inspect(other)}"
          |> Logger.info(tag: "invalid_http_id")

          {:error, :http_request_not_found}
      end
    end)
  end
end
