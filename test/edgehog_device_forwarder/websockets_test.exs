# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.WebSocketsTest do
  use EdgehogDeviceForwarder.CacheCase
  alias EdgehogDeviceForwarder.{HTTPRequests, WebSockets}

  setup_all do
    [empty_socket_2: spawn(fn -> 1 end)]
  end

  setup %{empty_socket: controller, empty_socket_2: websocket_socket} do
    request_id = HTTPRequests.new(controller)

    {:ok, _} = HTTPRequests.fetch(request_id, {:upgrade, :websocket})
    :ok = WebSockets.upgrade(request_id, websocket_socket)

    [socket_id: request_id]
  end

  describe "upgrade/2" do
    setup %{empty_socket: controller} do
      request_id = HTTPRequests.new(controller)

      [http_request_id: request_id]
    end

    test "does not allow an active request to be upgraded", %{
      http_request_id: request_id,
      empty_socket_2: websocket_socket
    } do
      assert {:error, :http_request_not_found} ==
               WebSockets.upgrade(request_id, websocket_socket)
    end

    test "saves the new socket to the cache using the old request id", %{
      http_request_id: request_id,
      empty_socket_2: websocket_socket
    } do
      # We allow upgrading only after fetching with {:upgrade, :websocket}
      HTTPRequests.fetch(request_id, {:upgrade, :websocket})

      assert :ok == WebSockets.upgrade(request_id, websocket_socket)
      assert {:ok, websocket_socket} == WebSockets.fetch(request_id)
    end
  end

  test "fetch/1 doesn't remove the socket_id from the cache", %{socket_id: socket_id} do
    assert {:ok, x} = WebSockets.fetch(socket_id)
    assert {:ok, x} == WebSockets.fetch(socket_id)
    assert {:ok, x} == WebSockets.fetch(socket_id)
  end

  test "close/1 removes the socket_id from the cache", %{socket_id: socket_id} do
    assert {:ok, _} = WebSockets.fetch(socket_id)
    assert :ok == WebSockets.close(socket_id)
    assert {:error, :websocket_not_found} == WebSockets.fetch(socket_id)
  end
end
