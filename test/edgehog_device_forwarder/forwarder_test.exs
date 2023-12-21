# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.ForwarderTest do
  use EdgehogDeviceForwarder.ForwarderCase

  alias EdgehogDeviceForwarder.Forwarder
  alias EdgehogDeviceForwarder.HTTPRequests
  alias EdgehogDeviceForwarder.WebSockets
  alias EdgehogDeviceForwarder.WebSockets.Data, as: WebSocketsData
  alias EdgehogDeviceForwarder.Tokens
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: ProtoHTTP
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket

  require Logger

  describe "http_to_device/2" do
    test "waits synchronously the response from the client", %{
      http_request: request,
      http_upgrade_request: request_upgrade,
      ping_pong_token: ping_pong_token
    } do
      assert {:respond, response} = Forwarder.http_to_device(ping_pong_token, request)
      assert response.body == request.body

      assert {{:upgrade, :websocket}, _response, %{socket_id: _socket_id, device: _device_socket}} =
               Forwarder.http_to_device(ping_pong_token, request_upgrade)
    end

    test "returns {:error, :request_timeout} if the device doesn't respond in time", %{
      http_response: request
    } do
      token = "new_token"

      # self won't respond
      Tokens.reserve(token)
      Tokens.register(token, self())
      assert {:error, :request_timeout} == Forwarder.http_to_device(token, request)
    end
  end

  test "ws_to_device/2 forwards the frames to the given device socket" do
    data = %{socket_id: "some_socket_id", device: self()}
    frame = {:text, "hello world"}

    assert :ok == Forwarder.ws_to_device(data, frame)
    assert_receive {:binary, response}

    assert {:ws, %ProtoWebSocket{socket_id: data.socket_id, message: frame}} ==
             ProtoMessage.decode(response).protocol
  end

  describe "to_user/2" do
    test "forwards the message to the target socket", %{
      http_response: response,
      http_upgrade_response: upgrade
    } do
      http_request_id = HTTPRequests.new(self())
      socket_data = %WebSocketsData{socket_id: http_request_id, device: self()}

      message = %ProtoHTTP{request_id: http_request_id, message: {:response, response}}

      %ProtoMessage{protocol: {:http, message}}
      |> ProtoMessage.encode()
      |> Forwarder.to_user()

      assert_receive {:respond, ^response}

      websocket_id = HTTPRequests.new(self())
      assert :ok == HTTPRequests.forward(websocket_id, upgrade)
      assert :ok == WebSockets.upgrade(websocket_id, self(), socket_data)

      frame = {:text, "hello world"}

      message = %ProtoWebSocket{socket_id: websocket_id, message: frame}

      %ProtoMessage{protocol: {:ws, message}}
      |> ProtoMessage.encode()
      |> Forwarder.to_user()

      assert_receive ^frame
    end

    test "tells the socket to reply with a close if the target websocket isn't known" do
      non_existing_id = "non_existing_id"

      message = %ProtoWebSocket{socket_id: non_existing_id, message: {:text, "hello world"}}

      message =
        %ProtoMessage{protocol: {:ws, message}}
        |> ProtoMessage.encode()

      assert {:reply, {:binary, close_message}} = Forwarder.to_user(message)
      assert {:ws, close_message} = ProtoMessage.decode(close_message).protocol

      assert %ProtoWebSocket{socket_id: ^non_existing_id, message: close_message} = close_message
      assert {:close, close_message} = close_message
      assert close_message.code == 4000
    end
  end
end
