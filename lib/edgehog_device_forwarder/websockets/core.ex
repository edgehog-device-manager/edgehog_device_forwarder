defmodule EdgehogDeviceForwarder.WebSockets.Core do
  @moduledoc """
  Implementation of the core functions for `EdgehogDeviceForwarder.WebSockets`.

  Functions in this module assume
  - The error checking has already been performed,
  - They are called within an isolated `ConCache` environment.
  """

  require Logger

  alias EdgehogDeviceForwarder.WebSockets.Data
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket

  @cache_id EdgehogDeviceForwarder.Caches.cache_id_for(EdgehogDeviceForwarder.WebSockets)

  @type user_socket :: pid()
  @type message ::
          {:text, String.t()}
          | {:binary, binary}
          | {:ping, binary}
          | {:pong, binary}
          | {:close, ProtoWebSocket.Close.t()}

  @doc """
  Finalize the upgrade of an HTTP connection to a WebSocket.

  Forwards all the queued messages to the socket.
  """
  @spec upgrade(EdgehogDeviceForwarder.HTTPRequests.id(), user_socket, Qex.t()) ::
          {:websocket, user_socket}
  def upgrade(request_id, user_socket, message_queue) do
    for message <- message_queue do
      send(user_socket, message)
    end

    "ws: upgrade: socket_id: #{inspect(request_id)}: created"
    |> Logger.debug(tag: "user_event")

    {:websocket, user_socket}
  end

  @doc """
  Enqueue the message.
  The message will be forwarded once the update is finalized.
  """
  @spec enqueue_message(Data.socket_id(), Qex.t(), message) :: :ok
  def enqueue_message(socket_id, message_queue, message) do
    updated_queue = Qex.push(message_queue, message)
    ConCache.dirty_put(@cache_id, socket_id, {:upgrading, :websocket, updated_queue})
  end

  @doc """
  Forward the message to the target WebSocket.
  """
  @spec forward(Data.socket_id(), user_socket, message) :: :ok
  def forward(socket_id, user_socket, {:close, close_data}) do
    device_start_socket_closing_handshake(socket_id)

    # we hide our close frame structure from the socket and instead
    # use standard socket close parameters
    close_message = {:close, {close_data.code, close_data.reason}}
    send(user_socket, close_message)

    :ok
  end

  def forward(_socket_id, user_socket, message) do
    send(user_socket, message)

    :ok
  end

  @doc """
  Start the WebSocket close handshake requested by the device.
  """
  @spec device_start_socket_closing_handshake(Data.socket_id()) :: :ok
  def device_start_socket_closing_handshake(socket_id) do
    "ws: forward: socket_id #{inspect(socket_id)}: begin device-requested closing handshake"
    |> Logger.debug(tag: "user_socket_closing")

    ConCache.dirty_put(@cache_id, socket_id, {:closing, :websocket, :device})
  end

  @doc """
  Start the WebSocket close handshake requested by the user.
  """
  @spec user_start_socket_closing_handshake(Data.socket_id(), user_socket) :: :ok
  def user_start_socket_closing_handshake(socket_id, user_socket) do
    "ws: close: socket_id#{inspect(socket_id)}: begin user-requested closing handshake"
    |> Logger.debug(tag: "user_socket_closing")

    send_close(user_socket, socket_id)
    ConCache.dirty_put(@cache_id, socket_id, {:closing, :websocket, :user})
  end

  @doc """
  Complete the WebSocket close handshake.
  """
  @spec socket_closing_handshake_complete(Data.socket_id()) :: :ok
  def socket_closing_handshake_complete(socket_id) do
    "ws: close: socket_id #{inspect(socket_id)}: completed"
    |> Logger.debug(tag: "user_socket_closing")

    ConCache.dirty_delete(@cache_id, socket_id)
  end

  @spec send_close(Data.device_socket(), Data.socket_id()) :: :ok
  defp send_close(socket, socket_id) do
    close_message = %ProtoWebSocket.Close{code: 1000, reason: ""}
    close_message = %ProtoWebSocket{socket_id: socket_id, message: {:close, close_message}}
    close_message = %ProtoMessage{protocol: {:ws, close_message}}
    close_message = {:binary, ProtoMessage.encode(close_message)}

    send(socket, close_message)
    :ok
  end
end
