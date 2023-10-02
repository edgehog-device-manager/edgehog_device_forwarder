# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Forwarder do
  @moduledoc """
  Handles protobuf encapsulation and message redirection between controllers and sockets
  """

  alias EdgehogDeviceForwarder.{Tokens, HTTPRequests, WebSockets}
  alias EdgehogDeviceForwarder.WebSockets.Data, as: WebSocketsData
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: ProtoHTTP
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket

  require Logger

  @request_timeout Application.compile_env!(
                     :edgehog_device_forwarder,
                     [EdgehogDeviceForwarder.Forwarder, :request_timeout]
                   )

  @doc """
  Forward the HTTP message to the device.
  """
  @spec http_to_device(Tokens.token(), ProtoHTTP.Request.t()) ::
          {:respond, ProtoHTTP.Response.t()}
          | {{:upgrade, :websocket}, ProtoHTTP.Response.t(), WebSocketsData.t()}
          | {:error, :request_timeout | :token_not_found}
  def http_to_device(token, request) do
    with {:ok, device_socket} <- Tokens.fetch_device_socket(token) do
      request_id = HTTPRequests.new(self())

      message = %ProtoHTTP{request_id: request_id, message: {:request, request}}

      message =
        %ProtoMessage{protocol: {:http, message}}
        |> ProtoMessage.encode()

      "sending http to device with request_id: #{inspect(request_id)}"
      |> Logger.debug(tag: "device_event")

      send(device_socket, {:binary, message})

      receive do
        {:respond, response} ->
          {:respond, response}

        {{:upgrade, :websocket}, response} ->
          socket_data = %WebSocketsData{socket_id: request_id, device: device_socket}
          {{:upgrade, :websocket}, response, socket_data}
      after
        @request_timeout -> {:error, :request_timeout}
      end
    end
  end

  @doc """
  Forward the WebSocket message to the device.
  """
  @spec ws_to_device(WebSocketsData.t(), WebSockets.message()) :: :ok
  def ws_to_device(socket_data, message) do
    %{socket_id: socket_id, device: device_socket} = socket_data

    message = %ProtoWebSocket{socket_id: socket_id, message: message}

    message =
      %ProtoMessage{protocol: {:ws, message}}
      |> ProtoMessage.encode()

    "sending websocket to device with socket_id: #{inspect(socket_id)}"
    |> Logger.debug(tag: "device_event")

    send(device_socket, {:binary, message})
    :ok
  end

  @doc """
  Forward the message received from the device back to the user process.
  """
  @spec to_user(binary) :: :ok | {:reply, WebSockets.message()}
  def to_user(response) do
    response = ProtoMessage.decode(response).protocol

    case response do
      {:ws, message} ->
        %ProtoWebSocket{socket_id: socket_id, message: message} = message

        case WebSockets.forward(socket_id, message) do
          :ok -> :ok
          {:error, :websocket_not_found} -> {:reply, close_message(socket_id)}
          {:error, :websocket_is_closing} -> :ok
        end

      {:http, %ProtoHTTP{message: {:response, _}} = http} ->
        %ProtoHTTP{request_id: request_id, message: {:response, response}} = http
        HTTPRequests.forward(request_id, response)
        :ok

      {:http, http} ->
        "Received HTTP Request from device, with id #{inspect(http.request_id)}"
        |> Logger.notice(tag: "invalid_request_from_device")

        :ok
    end
  end

  @spec close_message(WebSockets.id()) :: WebSockets.message()
  defp close_message(socket_id) do
    message =
      %ProtoWebSocket{
        socket_id: socket_id,
        message: {:close, %{code: 4000, reason: "Socket not found"}}
      }

    message =
      %ProtoMessage{protocol: {:ws, message}}
      |> ProtoMessage.encode()

    {:binary, message}
  end
end
