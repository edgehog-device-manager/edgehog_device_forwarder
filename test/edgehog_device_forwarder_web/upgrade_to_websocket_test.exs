# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarderWeb.UpgradeToWebSocketTest do
  use EdgehogDeviceForwarder.ForwarderCase

  alias EdgehogDeviceForwarder.Forwarder
  alias EdgehogDeviceForwarder.WebSockets
  alias EdgehogDeviceForwarder.WebSockets.Data, as: WebSocketsData
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.{Message, WebSocket}

  test "the user receives all messages from the device on the new socket right after creation", %{
    http_upgrade_request: request_upgrade,
    ping_pong_token: ping_pong_token
  } do
    {{:upgrade, :websocket}, _, %WebSocketsData{} = socket_data} =
      Forwarder.http_to_device(ping_pong_token, request_upgrade)

    original_messages =
      1..205
      |> Enum.map(&to_string/1)
      |> Enum.map(&{:text, &1})

    encoded_messages =
      original_messages
      |> Enum.map(&%WebSocket{socket_id: socket_data.socket_id, message: &1})
      |> Enum.map(&%Message{protocol: {:ws, &1}})
      |> Enum.map(&Message.encode/1)

    half =
      length(encoded_messages)
      |> div(2)

    {initial_batch, after_spawn_batch} = Enum.split(encoded_messages, half)

    Enum.each(initial_batch, &Forwarder.to_user/1)

    me = self()
    socket = spawn(fn -> user_socket(socket_data, me) end)

    Enum.each(after_spawn_batch, &Forwarder.to_user/1)

    send(socket, :done)

    received_messages =
      receive do
        x -> x
      end

    assert received_messages == original_messages
  end

  defp user_socket(socket_data, parent) do
    :ok = WebSockets.upgrade(socket_data.socket_id, self(), socket_data)

    receive do
      :done -> nil
    end

    {:messages, messages} = :erlang.process_info(self(), :messages)

    send(parent, messages)
  end
end
