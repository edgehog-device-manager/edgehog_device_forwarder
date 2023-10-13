# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Messages.WebSocket do
  use TypedStruct

  alias EdgehogDeviceForwarder.WebSockets
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket

  typedstruct do
    field :socket_id, WebSockets.id()
    field :frame, frame
  end

  @type frame ::
          {:text, String.t()}
          | {:binary, binary}
          | {:ping, binary}
          | {:pong, binary}
          | {:close, %{code: integer, reason: String.t()}}

  @spec from_proto(ProtoWebSocket.t()) :: t
  def from_proto(proto_ws) do
    %ProtoWebSocket{socket_id: socket_id, message: {type, content}} = proto_ws

    # close frames are protobuf structs
    content =
      case type do
        :close ->
          Map.from_struct(content)
          |> Map.drop([:__unknown_fields__])

        _ ->
          content
      end

    %__MODULE__{socket_id: socket_id, frame: {type, content}}
  end

  @spec to_proto(t) :: ProtoWebSocket.t()
  def to_proto(message) do
    %__MODULE__{socket_id: socket_id, frame: {type, content}} = message

    content =
      case type do
        :close -> %ProtoWebSocket.Close{code: content.code, reason: content.reason}
        _ -> content
      end

    %ProtoWebSocket{socket_id: socket_id, message: {type, content}}
  end

  @spec protocol :: :ws
  def protocol, do: :ws
end
