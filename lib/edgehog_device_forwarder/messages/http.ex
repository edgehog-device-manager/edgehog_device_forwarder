# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.Messages.HTTP do
  use TypedStruct

  alias EdgehogDeviceForwarder.HTTPRequests
  alias EdgehogDeviceForwarder.Messages.HTTP.Response
  alias EdgehogDeviceForwarder.Messages.HTTP.Request
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: ProtoHTTP

  typedstruct do
    field :request_id, HTTPRequests.id(), required: true
    field :message, Request.t() | Response.t(), required: true
  end

  @spec from_proto(ProtoHTTP.t()) :: t
  def from_proto(proto_http) do
    {type, message} = proto_http.message

    message =
      case type do
        :request -> Request.from_proto(message)
        :response -> Response.from_proto(message)
      end

    %__MODULE__{request_id: proto_http.request_id, message: message}
  end

  @spec to_proto(t) :: ProtoHTTP.t()
  def to_proto(message) do
    %__MODULE__{request_id: request_id, message: message} = message

    type = message.__struct__.type()
    message_proto = message.__struct__.to_proto(message)

    %ProtoHTTP{request_id: request_id, message: {type, message_proto}}
  end

  @spec protocol :: :http
  def protocol, do: :http
end

defmodule EdgehogDeviceForwarder.Messages.HTTP.Request do
  use TypedStruct

  typedstruct do
    field :path, String.t()
    field :method, String.t()
    field :query_string, String.t()
    field :headers, map
    field :body, binary
    field :port, integer
  end

  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http.Request, as: ProtoRequest

  @spec from_proto(ProtoRequest.t()) :: t
  def from_proto(proto_request) do
    %__MODULE__{
      path: proto_request.path,
      method: proto_request.method,
      query_string: proto_request.query_string,
      headers: proto_request.headers,
      body: proto_request.body,
      port: proto_request.port
    }
  end

  @spec to_proto(t) :: ProtoRequest.t()
  def to_proto(request) do
    %ProtoRequest{
      path: request.path,
      method: request.method,
      query_string: request.query_string,
      headers: request.headers,
      body: request.body,
      port: request.port
    }
  end

  @spec type :: :request
  def type, do: :request
end

defmodule EdgehogDeviceForwarder.Messages.HTTP.Response do
  use TypedStruct

  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http.Response, as: ProtoResponse

  typedstruct do
    field :status_code, integer
    field :headers, map
    field :body, binary
  end

  @spec from_proto(ProtoResponse.t()) :: t
  def from_proto(proto_response) do
    %__MODULE__{
      status_code: proto_response.status_code,
      headers: proto_response.headers,
      body: proto_response.body
    }
  end

  @spec to_proto(t) :: ProtoResponse.t()
  def to_proto(response) do
    %ProtoResponse{
      status_code: response.status_code,
      headers: response.headers,
      body: response.body
    }
  end

  @spec type :: :response
  def type, do: :response
end
