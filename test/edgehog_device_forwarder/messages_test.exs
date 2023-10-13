# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.MessagesTest do
  use ExUnit.Case

  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message, as: ProtoMessage
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: ProtoHTTP
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.WebSocket, as: ProtoWebSocket

  alias EdgehogDeviceForwarder.Messages
  alias EdgehogDeviceForwarder.Messages.{HTTP, WebSocket}

  setup do
    proto_request =
      %ProtoHTTP.Request{
        path: "/path/values",
        method: "GET",
        query_string: "my=value&other=thing",
        headers: %{"some" => "header", "other" => "string", "type" => "request"},
        body: "request body",
        port: 8080
      }

    proto_http_request =
      %ProtoHTTP{
        request_id: "request_id",
        message: {:request, proto_request}
      }

    proto_response =
      %ProtoHTTP.Response{
        headers: %{"some" => "header", "other" => "string", "type" => "response"},
        body: "response body"
      }

    proto_http_response =
      %ProtoHTTP{
        request_id: "request_id",
        message: {:response, proto_response}
      }

    proto_websocket =
      %ProtoWebSocket{
        socket_id: "socket_id",
        message: {:text, "message"}
      }

    proto_websocket_close =
      %ProtoWebSocket{
        socket_id: "socket_id_2",
        message: {:close, %ProtoWebSocket.Close{code: 4000, reason: "internal error"}}
      }

    [
      proto_http_request: proto_http_request,
      proto_http_response: proto_http_response,
      proto_request: proto_request,
      proto_response: proto_response,
      proto_websocket: proto_websocket,
      proto_websocket_close: proto_websocket_close
    ]
  end

  test "HTTP.from_proto/1 correctly parses the messages", %{
    proto_request: proto_request,
    proto_http_request: proto_http_request,
    proto_response: proto_response,
    proto_http_response: proto_http_response
  } do
    request = HTTP.from_proto(proto_http_request)
    assert request.request_id == proto_http_request.request_id
    assert is_struct(request.message, HTTP.Request)

    # Check that all the fields are equal
    request_fields = [:path, :method, :query_string, :headers, :body, :port]

    Enum.map(request_fields, fn field ->
      message_value = get_in(request.message, [Access.key!(field)])
      proto_value = get_in(proto_request, [Access.key!(field)])
      assert message_value == proto_value
    end)

    response = HTTP.from_proto(proto_http_response)
    assert is_struct(response.message, HTTP.Response)

    response_fields = [:status_code, :headers, :body]

    Enum.map(response_fields, fn field ->
      message_value = get_in(response.message, [Access.key!(field)])
      proto_value = get_in(proto_response, [Access.key!(field)])
      assert message_value == proto_value
    end)
  end

  test "WebSocket.from_proto/1 correctly parses the messages", %{
    proto_websocket: proto_websocket,
    proto_websocket_close: proto_websocket_close
  } do
    websocket = WebSocket.from_proto(proto_websocket)
    assert websocket.socket_id == proto_websocket.socket_id

    {type, payload} = websocket.frame
    {proto_type, proto_payload} = proto_websocket.message
    assert type == proto_type

    case type do
      :close ->
        assert payload.code == proto_payload.code
        assert payload.code == proto_payload.code

      _ ->
        assert payload == proto_payload
    end

    websocket_close = WebSocket.from_proto(proto_websocket_close)
    assert websocket_close.socket_id == proto_websocket_close.socket_id

    {type, payload} = websocket.frame
    {proto_type, proto_payload} = proto_websocket.message
    assert type == proto_type

    case type do
      :close ->
        assert payload.code == proto_payload.code
        assert payload.code == proto_payload.code

      _ ->
        assert payload == proto_payload
    end
  end

  describe "Messages.encode/1 correctly encodes the message" do
    test "from an http message", %{
      proto_http_request: proto_http_request,
      proto_http_response: proto_http_response
    } do
      request = HTTP.from_proto(proto_http_request)
      proto_message = %ProtoMessage{protocol: {:http, proto_http_request}}

      assert(
        Messages.encode(request) ==
          ProtoMessage.encode(proto_message)
      )

      response = HTTP.from_proto(proto_http_response)
      proto_message = %ProtoMessage{protocol: {:http, proto_http_response}}
      assert Messages.encode(response) == ProtoMessage.encode(proto_message)
    end

    test "from a websocket frame", %{
      proto_websocket: proto_websocket,
      proto_websocket_close: proto_websocket_close
    } do
      websocket = WebSocket.from_proto(proto_websocket)
      proto_message = %ProtoMessage{protocol: {:ws, proto_websocket}}
      assert Messages.encode(websocket) == ProtoMessage.encode(proto_message)

      websocket_close = WebSocket.from_proto(proto_websocket_close)
      proto_message_close = %ProtoMessage{protocol: {:ws, proto_websocket_close}}
      assert Messages.encode(websocket_close) == ProtoMessage.encode(proto_message_close)
    end
  end

  describe "Messages.decode/1 correctly decodes the message" do
    test "with http", %{proto_http_request: original} do
      encoded =
        %ProtoMessage{protocol: {:http, original}}
        |> ProtoMessage.encode()

      assert HTTP.from_proto(original) == Messages.decode(encoded)
    end

    test "with websocket", %{proto_websocket: original} do
      encoded = %ProtoMessage{protocol: {:ws, original}} |> ProtoMessage.encode()

      assert WebSocket.from_proto(original) == Messages.decode(encoded)
    end
  end
end
