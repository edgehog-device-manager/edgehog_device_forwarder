# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.HTTPRequests do
  @moduledoc """
  Interface to the cache for the HTTP requests.
  """

  require Logger

  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http.Response, as: HTTPResponse
  alias EdgehogDeviceForwarder.HTTPRequests.Core
  alias EdgehogDeviceForwarder.HTTPRequests.Errors

  @table EdgehogDeviceForwarder.Caches.cache_id_for(__MODULE__)

  @type id :: binary()
  @type controller :: pid()

  @doc """
  Register a new HTTP Request for the given controller and give back its request id.
  """
  @spec new(controller) :: id
  def new(controller) do
    request_id = UUID.uuid4(:raw)

    case ConCache.insert_new(@table, request_id, {:http, controller}) do
      :ok -> request_id
      {:error, :already_exists} -> new(controller)
    end
  end

  @doc """
  Forward an HTTP Response to its controller.
  """
  @spec forward(id, HTTPResponse.t()) :: :ok | {:error, :http_request_not_found}
  def forward(request_id, response) do
    ConCache.isolated(@table, request_id, fn ->
      case ConCache.get(@table, request_id) do
        {:http, controller} ->
          Core.forward(controller, request_id, response)

        other ->
          Errors.forward_to_invalid_request_id(request_id, other)
      end
    end)
  end
end
