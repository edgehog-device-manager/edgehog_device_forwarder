# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.DeviceSocketTest do
  use EdgehogDeviceForwarder.CacheCase
  use EdgehogDeviceForwarder.MessageCase
  use EdgehogDeviceForwarderWeb.ConnCase

  alias EdgehogDeviceForwarderWeb.DeviceSocket
  alias EdgehogDeviceForwarder.Tokens
  alias EdgehogDeviceForwarder.WebSockets.Data
  alias EdgehogDeviceForwarder.HTTPRequests
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket

  describe "connect/1" do
    test "returns an error when the session param is missing" do
      assert {:error, :unauthenticated} == DeviceSocket.connect(%{params: %{}})
    end

    test "returns an error when the token is already in use" do
      :ok = Tokens.reserve("token_in_use")

      assert {:error, :token_already_exists} ==
               DeviceSocket.connect(%{params: %{"session" => "token_in_use"}})
    end

    test "reserves the token and returns the state" do
      assert {:ok, %{token: "some_token"}} =
               DeviceSocket.connect(%{params: %{"session" => "some_token"}})

      assert {:error, :token_already_exists} ==
               DeviceSocket.connect(%{params: %{"session" => "some_token"}})
    end
  end

  describe "init/1" do
    test "registers the device socket and returns the state" do
      :ok = Tokens.reserve("some_token")
      state = %{token: "some_token"}

      assert {:ok, ^state} = DeviceSocket.init(state)
      assert {:ok, device_socket} = Tokens.fetch_device_socket("some_token")
      assert device_socket == self()
    end
  end

  describe "handle_in/2" do
    test "returns {:ok, state} when the message is forwarded", %{
      socket: controller,
      http_upgrade_response: upgrade
    } do
      request_id = HTTPRequests.new(controller)
      :ok = HTTPRequests.forward(request_id, upgrade)

      state = %Data{socket_id: request_id, device: self()}
      message = ws_message(request_id, {:text, "hello"})

      assert {:ok, ^state} = DeviceSocket.handle_in({message, [opcode: :binary]}, state)
    end

    test "returns a close reply when the websocket is not found" do
      state = %Data{socket_id: "non_existing_id", device: self()}
      message = ws_message("non_existing_id", {:text, "hello"})

      assert {:reply, :ok, {:binary, close_message}, ^state} =
               DeviceSocket.handle_in({message, [opcode: :binary]}, state)

      assert {:ws, close_message} = ProtoMessage.decode(close_message).protocol
      assert {:close, %ProtoWebSocket.Close{code: 4000}} = close_message.message
    end
  end

  describe "handle_info/2" do
    test "pushes the message to the device" do
      state = %Data{socket_id: "some_id", device: self()}

      assert {:push, {:binary, "data"}, ^state} =
               DeviceSocket.handle_info({:binary, "data"}, state)
    end
  end

  describe "terminate/2" do
    test "returns :ok" do
      assert :ok == DeviceSocket.terminate(:normal, %{})
    end
  end

  describe "connection_error/2" do
    test "sends 401 for unauthenticated connections", %{conn: conn} do
      conn = DeviceSocket.connection_error(conn, :unauthenticated)
      assert conn.status == 401
    end

    test "sends 409 for already used tokens", %{conn: conn} do
      conn = DeviceSocket.connection_error(conn, :token_already_exists)
      assert conn.status == 409
    end
  end

  defp ws_message(socket_id, message) do
    message = %ProtoWebSocket{socket_id: socket_id, message: message}

    %ProtoMessage{protocol: {:ws, message}}
    |> ProtoMessage.encode()
  end
end
