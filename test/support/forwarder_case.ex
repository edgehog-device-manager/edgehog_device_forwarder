# Copyright 2023 SECO Mind Srl
# SPDX-License-Identifier: Apache-2.0

defmodule EdgehogDeviceForwarder.ForwarderCase do
  use ExUnit.CaseTemplate
  use EdgehogDeviceForwarder.CacheCase
  use EdgehogDeviceForwarder.MessageCase

  alias EdgehogDeviceForwarder.Tokens
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Message
  alias EdgehogDeviceForwarderProto.Edgehog.Device.Forwarder.Http, as: HTTP
  alias EdgehogDeviceForwarder.Forwarder

  setup do
    me = self()
    ping_pong_socket = spawn(fn -> ping_pong(me) end)

    [ping_pong_token: register_device(ping_pong_socket)]
  end

  def ping_pong(target, response_function \\ &make_response/1) do
    receive do
      {:binary, message} ->
        message
        |> Message.decode()
        |> then(& &1.protocol)
        |> response_function.()
        |> then(&%Message{protocol: &1})
        |> Message.encode()
        |> Forwarder.to_user()

      {other, message} ->
        raise "Expected binary message, got #{inspect(message)} of type #{inspect(other)}"
    end

    ping_pong(target)
  end

  defp make_response({:http, %HTTP{message: {:request, _}} = http}) do
    %HTTP{message: {:request, request}, request_id: id} = http

    status_code =
      with {:ok, status} <- Map.fetch(request.headers, "status-code"),
           {status, ""} <- Integer.parse(status) do
        status
      else
        _ -> 200
      end

    headers =
      with 101 <- status_code,
           {:ok, protocol} <- Map.fetch(request.headers, "upgrade-to") do
        Map.put(request.headers, "upgrade", protocol)
      else
        _ -> request.headers
      end

    headers = Map.drop(headers, ["upgrade-to", "status-code"])

    response = %HTTP.Response{
      status_code: status_code,
      body: request.body,
      headers: headers
    }

    {:http, %HTTP{request_id: id, message: {:response, response}}}
  end

  defp make_response({:ws, _} = message), do: message

  defp register_device(socket) do
    token = UUID.uuid4()

    case Tokens.reserve(token) do
      :ok ->
        :ok = Tokens.register(token, socket)
        token

      {:error, :already_exists} ->
        register_device(socket)
    end
  end
end
