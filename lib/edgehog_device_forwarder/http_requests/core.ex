defmodule EdgehogDeviceForwarder.HTTPRequests.Core do
  @moduledoc """
  Implementation of the core functions for `EdgehogDeviceForwarder.HTTPRequests`.

  Functions in this module assume
  - The error checking has already been performed,
  - They are called within an isolated `ConCache` environment.
  """
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: HTTP

  @table EdgehogDeviceForwarder.Caches.cache_id_for(EdgehogDeviceForwarder.HTTPRequests)

  @type controller :: pid()
  @type id :: binary()

  @doc """
  Forward the response back to the controller.

  This function is also responsible for updating the cache accordingly to the response
  - In case of a normal response, the request id is deleted from the cache
  - In case of an upgrade to websocket response, the request_id is marked as upgrading
  """
  @spec forward(controller, id, HTTP.Response.t()) :: :ok
  def forward(controller, request_id, response) do
    action = response_action(response)

    case action do
      :respond ->
        ConCache.dirty_delete(@table, request_id)

      {:upgrade, :websocket} ->
        ConCache.dirty_put(@table, request_id, {:upgrading, :websocket, Qex.new()})
    end

    send(controller, {action, response})

    :ok
  end

  @spec response_action(HTTP.Response.t()) :: :respond | {:upgrade, :websocket}
  defp response_action(response) do
    %HTTP.Response{status_code: status_code, headers: headers} = response

    if status_code == 101 and has_websocket_upgrade_header?(headers) do
      {:upgrade, :websocket}
    else
      :respond
    end
  end

  @spec has_websocket_upgrade_header?(map) :: boolean()
  defp has_websocket_upgrade_header?(headers) do
    headers
    |> Map.get("upgrade", "")
    |> String.downcase(:ascii)
    |> String.split(~r",\s*")
    |> Enum.member?("websocket")
  end
end
