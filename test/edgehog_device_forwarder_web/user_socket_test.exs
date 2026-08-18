# Copyright 2024-2026 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UserSocketTest do
  use EdgehogDeviceForwarder.CacheCase
  use EdgehogDeviceForwarder.MessageCase

  alias EdgehogDeviceForwarderWeb.UserSocket
  alias EdgehogDeviceForwarder.WebSockets.Data
  alias EdgehogDeviceForwarder.HTTPRequests

  describe "init/1" do
    test "returns {:ok, state} if the request can be upgraded", %{
      socket: controller,
      http_upgrade_response: upgrade
    } do
      request_id = HTTPRequests.new(controller)
      :ok = HTTPRequests.forward(request_id, upgrade)

      state = %Data{socket_id: request_id, device: self()}
      assert {:ok, ^state} = UserSocket.init(state)
    end

    test "stops if the request id is not found" do
      state = %Data{socket_id: "non_existing_id", device: self()}

      assert {:stop, {:error, :http_request_not_found}, ^state} = UserSocket.init(state)
    end
  end

  describe "handle_in/2" do
    test "forwards the message to the device socket" do
      state = %Data{socket_id: "some_id", device: self()}

      assert {:ok, ^state} = UserSocket.handle_in({"hello", [opcode: :text]}, state)
      assert_receive {:binary, _message}
    end
  end

  describe "handle_info/2" do
    test "stops the socket on error" do
      state = %Data{socket_id: "some_id", device: self()}

      assert {:stop, {:error, :some_reason}, ^state} =
               UserSocket.handle_info({:error, :some_reason}, state)
    end

    test "stops the socket on close" do
      state = %Data{socket_id: "some_id", device: self()}

      assert {:stop, :normal, {1000, ""}, ^state} =
               UserSocket.handle_info({:close, {1000, ""}}, state)
    end

    test "pushes other messages" do
      state = %Data{socket_id: "some_id", device: self()}

      assert {:push, {:binary, "data"}, ^state} = UserSocket.handle_info({:binary, "data"}, state)
    end
  end
end
