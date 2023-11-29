# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.WebSocketsTest do
  use EdgehogDeviceForwarder.CacheCase
  use EdgehogDeviceForwarder.MessageCase
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket
  alias EdgehogDeviceForwarder.{HTTPRequests, WebSockets}
  alias EdgehogDeviceForwarder.WebSockets.Data

  require Logger

  @valid_message {:text, "1"}

  setup %{
    socket: controller,
    http_upgrade_response: upgrade
  } do
    me = self()

    request_id = HTTPRequests.new(controller)
    socket = spawn(fn -> user_socket() end)

    data = %Data{socket_id: request_id, device: me}
    :ok = HTTPRequests.forward(request_id, upgrade)
    :ok = WebSockets.upgrade(request_id, socket, data)

    [
      socket_id: request_id,
      device_socket: me,
      socket_data: data,
      user_socket: socket
    ]
  end

  describe "upgrade/3" do
    setup %{socket: controller} do
      request_id = HTTPRequests.new(controller)
      upgrade_data = %Data{socket_id: request_id, device: self()}

      [http_request_id: request_id, upgrade_data: upgrade_data]
    end

    test "returns an error if it called without first forwarding an upgrade request", %{
      http_request_id: request_id,
      socket_data: data,
      socket: websocket_socket
    } do
      assert {:error, :http_request_not_found} ==
               WebSockets.upgrade(request_id, websocket_socket, data)
    end

    test "saves the new socket to the cache using the old request id", %{
      http_request_id: request_id,
      socket_data: data,
      http_upgrade_response: upgrade
    } do
      message = {:text, "test"}

      # We allow upgrading only after forwarding an upgrade request
      HTTPRequests.forward(request_id, upgrade)

      assert :ok == WebSockets.upgrade(request_id, self(), data)
      assert :ok == WebSockets.forward(request_id, message)
      assert_receive ^message
    end
  end

  describe "forward/2" do
    test "sends the message to the target socket", %{
      socket: controller,
      socket_data: data,
      http_upgrade_response: upgrade
    } do
      # insert websocket with target self()
      request_id = HTTPRequests.new(controller)
      :ok = HTTPRequests.forward(request_id, upgrade)
      :ok = WebSockets.upgrade(request_id, self(), data)

      # Clean mailbox to check messages received
      cleanup_mailbox()

      # assert that we receive all messages forwarded towards self()
      messages = [{:text, "1"}, {:text, "2"}]

      for message <- messages do
        :ok = WebSockets.forward(request_id, message)
      end

      {:messages, messages_received} = :erlang.process_info(self(), :messages)
      assert messages == messages_received
    end

    test "doesn't remove the socket_id from the cache", %{socket_id: socket_id} do
      assert :ok == WebSockets.forward(socket_id, @valid_message)
      assert :ok == WebSockets.forward(socket_id, @valid_message)
      assert :ok == WebSockets.forward(socket_id, @valid_message)
    end
  end

  describe "close/2 coming from the user" do
    test "marks the socket_id as :closing", %{socket_id: socket_id} do
      WebSockets.close(socket_id, self())
      assert {:error, :websocket_is_closing} == WebSockets.forward(socket_id, @valid_message)
    end

    test "sends a close message to the device", %{socket_id: socket_id} do
      assert :ok == WebSockets.close(socket_id, self())
      assert_receive {:binary, close_message}
      assert {:ws, close_message} = ProtoMessage.decode(close_message).protocol
      assert {:close, _} = close_message.message
    end
  end

  test "close/2 called after receiving a close from the device deletes the socket_id", %{
    socket_id: socket_id
  } do
    close_message = {:close, %ProtoWebSocket.Close{code: 1000, reason: ""}}
    assert :ok == WebSockets.forward(socket_id, close_message)
    assert :ok == WebSockets.close(socket_id, self())
    assert {:error, :websocket_not_found} == WebSockets.forward(socket_id, @valid_message)
  end

  def user_socket do
    receive do
      x -> Logger.debug("Received message #{inspect(x)}", tag: "websocket_test")
    end

    user_socket()
  end

  defp cleanup_mailbox do
    receive do
      _ -> cleanup_mailbox()
    after
      0 -> nil
    end
  end
end
