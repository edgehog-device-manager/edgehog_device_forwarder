# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Messages do
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarder.Messages.WebSocket
  alias EdgehogDeviceForwarder.Messages.HTTP

  @type t :: HTTP.t() | WebSocket.t()

  @spec decode(binary) :: t()
  def decode(encoded_message) do
    ProtoMessage.decode(encoded_message).protocol
    |> case do
      {:http, proto_http} -> HTTP.from_proto(proto_http)
      {:ws, proto_ws} -> WebSocket.from_proto(proto_ws)
    end
  end

  @spec encode(t()) :: binary
  def encode(message) do
    type = message.__struct__
    protocol = type.protocol()
    proto_message = type.to_proto(message)

    %ProtoMessage{protocol: {protocol, proto_message}}
    |> ProtoMessage.encode()
  end
end
